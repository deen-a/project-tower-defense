import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/tower.dart';
import '../models/enemy.dart';
import '../models/projectile.dart';
import 'chunk_manager.dart';

class GameState {
  List<Tower> towers = [];
  List<Enemy> enemies = [];
  List<Projectile> projectiles = [];
  TowerPlacement? currentPlacement;
  int coins = 2000000;
  int waveNumber = 0;
  bool isWaveActive = false;
  double baseHealth = 100.0; // Health base/garis finish
  double maxBaseHealth = 100.0;
  
  // Chunk optimization
  final ChunkManager chunkManager = ChunkManager();
  Set<String> detailedChunks = {};
  
  void updateDetailedChunks() {
    detailedChunks.clear();
    
    // Add chunks with towers
    for (var tower in towers) {
      final (chunkX, chunkY) = ChunkManager.worldToChunk(tower.pixelPosition);
      detailedChunks.add('$chunkX,$chunkY');
      
      // Tambah chunks di sekitar tower untuk range
      final range = tower.specs.rangePixels;
      final rangeInChunks = (range / ChunkManager.chunkSize).ceil();
      
      for (int dx = -rangeInChunks; dx <= rangeInChunks; dx++) {
        for (int dy = -rangeInChunks; dy <= rangeInChunks; dy++) {
          detailedChunks.add('${chunkX + dx},${chunkY + dy}');
        }
      }
    }
    
    // Add chunks with enemies
    for (var enemy in enemies) {
      final (chunkX, chunkY) = ChunkManager.worldToChunk(enemy.currentPosition);
      detailedChunks.add('$chunkX,$chunkY');
      
      // Tambah chunks di sekitar enemy
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          detailedChunks.add('${chunkX + dx},${chunkY + dy}');
        }
      }
    }
    
    // Add chunks with placement preview
    if (currentPlacement?.gridPosition != null) {
      final pos = currentPlacement!.pixelPosition!;
      final (chunkX, chunkY) = ChunkManager.worldToChunk(pos);
      
      // Add 3x3 area around placement
      for (int dx = -2; dx <= 2; dx++) {
        for (int dy = -2; dy <= 2; dy++) {
          detailedChunks.add('${chunkX + dx},${chunkY + dy}');
        }
      }
    }
  }
  
  bool shouldRenderDetailedChunk(String chunkKey) {
    return detailedChunks.contains(chunkKey);
  }
  
  final ValueNotifier<int> updateNotifier = ValueNotifier<int>(0);

  void update(double dt) {
    // Update enemies
    final List<Enemy> enemiesToRemove = [];
    
    for (var enemy in enemies) {
      enemy.update(dt);
      
      // Check if enemy reached end
      if (enemy.reachedEnd) {
        baseHealth -= enemy.remainingHealthDamage;
        enemiesToRemove.add(enemy);
      }
      
      // Check if enemy died
      if (!enemy.isAlive) {
        // Add coins for kill
        coins += (enemy.maxHealth / 10).ceil();
        enemiesToRemove.add(enemy);
      }
    }
    
    // Remove enemies that reached end or died
    enemies.removeWhere((enemy) => enemiesToRemove.contains(enemy));
    
    // Update projectiles
    projectiles.removeWhere((proj) => !proj.isActive);
    
    for (var projectile in projectiles) {
      projectile.update(dt);
    }
    
    // Update towers
    for (var tower in towers) {
      tower.update(dt);
      
      // Tower shooting logic
      if (tower.canFire() && enemies.isNotEmpty) {
        // Find enemy in range
        for (var enemy in enemies) {
          final distance = (tower.pixelPosition - enemy.currentPosition).distance;
          
          if (distance <= tower.specs.rangePixels && enemy.isAlive) {
            // Create projectile
            final projectileType = _getProjectileType(tower.type);
            final projectile = Projectile(
              type: projectileType,
              damage: tower.specs.damage.toDouble(),
              speed: 300, // pixels per second
              startPosition: tower.pixelPosition,
              target: enemy,
              color: tower.specs.color,
            );
            
            projectiles.add(projectile);
            tower.resetCooldown();
            break; // Shoot one enemy at a time
          }
        }
      }
    }
    
    // Check base health
    if (baseHealth <= 0) {
      baseHealth = 0;
      // Game over logic here
    }
    
    // Update detailed chunks
    updateDetailedChunks();

    // Notify listeners untuk rebuild UI
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
}