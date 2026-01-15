import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/tower.dart';
import '../models/enemy.dart';
import '../models/projectile.dart';
import 'chunk_manager.dart';
import './game_constants.dart';

class GameState {
  List<Tower> towers = [];
  List<Enemy> enemies = [];
  List<Projectile> projectiles = [];
  TowerPlacement? currentPlacement;
  int coins = 2000000;
  int waveNumber = 0;
  bool isWaveActive = false;
  double baseHealth = 100.0;
  double maxBaseHealth = 100.0;
  
  // Chunk optimization
  final ChunkManager chunkManager = ChunkManager();
  Set<String> detailedChunks = {};
  
  // Untuk update UI
  final ValueNotifier<int> updateNotifier = ValueNotifier<int>(0);
  
  // Performance counter
  int _frameCount = 0;
  DateTime? _lastFpsCheck;
  double _currentFps = 60.0;
  
  void updateDetailedChunks() {
    final previousDetailedChunks = Set<String>.from(detailedChunks);
    detailedChunks.clear();
    
    // HANYA chunks dengan towers (tidak tambah area sekitarnya)
    for (var tower in towers) {
      final (chunkX, chunkY) = ChunkManager.worldToChunk(tower.pixelPosition);
      detailedChunks.add('$chunkX,$chunkY');
    }
    
    // HANYA chunks dengan enemies (tidak tambah area sekitarnya)
    for (var enemy in enemies) {
      final (chunkX, chunkY) = ChunkManager.worldToChunk(enemy.currentPosition);
      detailedChunks.add('$chunkX,$chunkY');
    }
    
    // HANYA chunks dengan placement preview (tidak tambah area sekitarnya)
    if (currentPlacement?.gridPosition != null) {
      final pos = currentPlacement!.pixelPosition!;
      final (chunkX, chunkY) = ChunkManager.worldToChunk(pos);
      detailedChunks.add('$chunkX,$chunkY');
    }
    
    // Only notify if changed (performance optimization)
    if (!_setsEqual(previousDetailedChunks, detailedChunks)) {
      updateNotifier.value++;
    }
  }
  
  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (var item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
  
  bool shouldRenderDetailedChunk(String chunkKey) {
    return detailedChunks.contains(chunkKey);
  }
  
  void update(double dt) {
    _frameCount++;
    
    // Update enemies
    final List<Enemy> enemiesToRemove = [];
    
    for (var enemy in enemies) {
      enemy.update(dt);
      
      // Check if enemy reached end
      if (enemy.reachedEnd) {
        baseHealth -= enemy.remainingHealthDamage;
        enemiesToRemove.add(enemy);
      }
    }
    
    // Remove enemies that reached end
    enemies.removeWhere((enemy) => enemiesToRemove.contains(enemy));
    
    // Update projectiles dan check collision
    final List<Projectile> projectilesToRemove = [];
    final List<Enemy> enemiesToDamage = [];
    
    for (var projectile in projectiles) {
      projectile.update(dt);
      
      // Check collision dengan target enemy
      if (!projectile.isActive) {
        projectilesToRemove.add(projectile);
        
        // Damage enemy jika projectile sampai
        if (projectile.target.isAlive) {
          projectile.target.takeDamage(projectile.damage);
          
          // Splash damage
          if (projectile.splashRadius > 0) {
            for (var otherEnemy in enemies) {
              if (otherEnemy != projectile.target && 
                  (otherEnemy.currentPosition - projectile.target.currentPosition).distance <= projectile.splashRadius) {
                otherEnemy.takeDamage(projectile.damage * 0.5); // 50% splash damage
              }
            }
          }
          
          // Check if enemy died
          if (!projectile.target.isAlive) {
            coins += (projectile.target.maxHealth / 10).ceil();
          }
        }
      }
      
      // Remove jika miss atau out of bounds
      final distanceToTarget = (projectile.currentPosition - projectile.startPosition).distance;
      if (distanceToTarget > 1000) { // Max range
        projectilesToRemove.add(projectile);
      }
    }
    
    // Remove projectiles
    projectiles.removeWhere((proj) => projectilesToRemove.contains(proj));
    
    // Update towers
    for (var tower in towers) {
      tower.update(dt);
      
      // Tower shooting logic - optimasi: cari enemy terdekat dalam range
      if (tower.canFire() && enemies.isNotEmpty) {
        Enemy? closestEnemy;
        double closestDistance = double.infinity;
        
        for (var enemy in enemies) {
          if (!enemy.isAlive) continue;
          
          final distance = (tower.pixelPosition - enemy.currentPosition).distance;
          if (distance <= tower.specs.rangePixels && distance < closestDistance) {
            closestDistance = distance;
            closestEnemy = enemy;
          }
        }
        
        if (closestEnemy != null) {
          // Create projectile
          final projectileType = _getProjectileType(tower.type);
          final projectile = Projectile(
            type: projectileType,
            damage: tower.specs.damage.toDouble(),
            speed: _getProjectileSpeed(tower.type),
            startPosition: tower.pixelPosition,
            target: closestEnemy,
            splashRadius: tower.type == 'flamethrower' ? GameConstants.metersToPixels(3.0) : 0,
            color: tower.specs.color,
          );
          
          projectiles.add(projectile);
          tower.resetCooldown();
        }
      }
    }
    
    // Check base health
    if (baseHealth <= 0) {
      baseHealth = 0;
      isWaveActive = false;
    }
    
    // Check if wave is complete
    if (isWaveActive && enemies.isEmpty) {
      isWaveActive = false;
      coins += 100 * waveNumber; // Bonus coin
    }
    
    // Update FPS counter
    final now = DateTime.now();
    if (_lastFpsCheck == null) {
      _lastFpsCheck = now;
    } else if (now.difference(_lastFpsCheck!).inSeconds >= 1) {
      _currentFps = _frameCount.toDouble();
      _frameCount = 0;
      _lastFpsCheck = now;
    }
    
    // Update detailed chunks
    updateDetailedChunks();
    
    // Notify UI untuk update
    updateNotifier.value++;
  }
  
  ProjectileType _getProjectileType(String towerType) {
    switch (towerType) {
      case 'basic':
        return ProjectileType.basic;
      case 'burst':
        return ProjectileType.rapid;
      case 'railgun':
        return ProjectileType.laser;
      case 'flamethrower':
        return ProjectileType.flame;
      default:
        return ProjectileType.basic;
    }
  }
  
  double _getProjectileSpeed(String towerType) {
    switch (towerType) {
      case 'basic':
        return 300;
      case 'burst':
        return 500;
      case 'railgun':
        return 1000;
      case 'flamethrower':
        return 200;
      default:
        return 300;
    }
  }
  
  double get fps => _currentFps;
}