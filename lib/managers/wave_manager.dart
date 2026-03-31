import 'dart:math';
import 'package:flutter/material.dart';

class WaveManager {
  final GameState gameState;
  final GameModeManager gameModeManager;
  int currentWave = 0;
  bool isWaveActive = false;
  double waveTimer = 0;
  int enemiesSpawned = 0;
  int totalEnemiesThisWave = 0;
  
  final List<Enemy> activeEnemies = [];
  final List<WaveDefinition> waveDefinitions = [];
  
  WaveManager(this.gameState, this.gameModeManager) {
    _initializeWaveDefinitions();
  }
  
  void _initializeWaveDefinitions() {
    // Campaign waves
    waveDefinitions.addAll([
      WaveDefinition(waveNumber: 1, enemies: [
        WaveEnemy(type: "basic", count: 5, spawnInterval: 1.0),
      ]),
      WaveDefinition(waveNumber: 2, enemies: [
        WaveEnemy(type: "basic", count: 8, spawnInterval: 0.8),
        WaveEnemy(type: "speedy", count: 3, spawnInterval: 2.0),
      ]),
      WaveDefinition(waveNumber: 3, enemies: [
        WaveEnemy(type: "basic", count: 10, spawnInterval: 0.7),
        WaveEnemy(type: "speedy", count: 5, spawnInterval: 1.5),
        WaveEnemy(type: "tank", count: 2, spawnInterval: 3.0),
      ]),
      // Add more waves...
      WaveDefinition(waveNumber: 10, isBossWave: true, enemies: [
        WaveEnemy(type: "boss", count: 1, spawnInterval: 0.0),
      ]),
    ]);
    
    // Endless mode waves (generated dynamically)
    _generateEndlessWaves();
  }
  
  void _generateEndlessWaves() {
    for (int i = 11; i <= 20; i++) {
      waveDefinitions.add(_createEndlessWave(i));
    }
  }
  
  WaveDefinition _createEndlessWave(int waveNumber) {
    final random = Random();
    final isBossWave = waveNumber % 5 == 0;
    
    if (isBossWave) {
      return WaveDefinition(
        waveNumber: waveNumber,
        isBossWave: true,
        enemies: [WaveEnemy(type: "boss", count: 1, spawnInterval: 0.0)],
      );
    }
    
    final enemyTypes = ["basic", "speedy", "tank", "flying", "elite_stun", "lifesteal"];
    final enemies = <WaveEnemy>[];
    
    final totalEnemies = 10 + (waveNumber * 2);
    var remaining = totalEnemies;
    
    while (remaining > 0) {
      final type = enemyTypes[random.nextInt(enemyTypes.length)];
      final count = random.nextInt(min(remaining, 8)) + 1;
      final interval = 0.5 + random.nextDouble() * 1.5;
      
      enemies.add(WaveEnemy(
        type: type,
        count: count,
        spawnInterval: interval,
      ));
      
      remaining -= count;
    }
    
    return WaveDefinition(
      waveNumber: waveNumber,
      enemies: enemies,
    );
  }
  
  void startNextWave() {
    if (isWaveActive) return;
    
    currentWave++;
    isWaveActive = true;
    enemiesSpawned = 0;
    waveTimer = 0;
    
    final waveDef = _getCurrentWaveDefinition();
    totalEnemiesThisWave = waveDef.totalEnemies;
    
    gameState.isWaveActive = true;
    gameState.notifyListeners();
  }
  
  void update(double dt, MapData mapData, TowerManager towerManager) {
    if (!isWaveActive) return;
    
    waveTimer += dt;
    final waveDef = _getCurrentWaveDefinition();
    
    // Spawn enemies
    for (var waveEnemy in waveDef.enemies) {
      if (waveEnemy.spawnedCount < waveEnemy.count && 
          waveTimer >= waveEnemy.nextSpawnTime) {
        
        final enemy = _createEnemy(waveEnemy.type, mapData.path.first);
        if (enemy != null) {
          activeEnemies.add(enemy);
          waveEnemy.spawnedCount++;
          waveEnemy.nextSpawnTime = waveTimer + waveEnemy.spawnInterval;
          enemiesSpawned++;
        }
      }
    }
    
    // Update active enemies
    for (var enemy in activeEnemies.toList()) {
      enemy.update(dt, mapData);
      
      // Check if enemy reached the end
      if (_hasReachedEnd(enemy, mapData)) {
        gameState.takeDamage(10); // Base damage per enemy
        activeEnemies.remove(enemy);
      }
      
      // Check for ability usage
      if (enemy.abilities.isNotEmpty) {
        final nearbyTowers = towerManager.getTowersInRange(enemy.position, enemy.abilities.first.range);
        enemy.useAbilities(nearbyTowers);
      }
    }
    
    // Check wave completion
    if (enemiesSpawned >= totalEnemiesThisWave && activeEnemies.isEmpty) {
      completeWave();
    }
  }
  
  void completeWave() {
    isWaveActive = false;
    gameState.isWaveActive = false;
    
    // Reward coins
    final baseReward = 50 + (currentWave * 10);
    gameState.addCoins(baseReward);
    
    // Special rewards for boss waves
    final waveDef = _getCurrentWaveDefinition();
    if (waveDef.isBossWave) {
      gameState.addCoins(200);
      // Award skill points for boss defeat
      // gameState.skillPoints += 1;
      
      // Change map in endless mode
      if (gameModeManager.shouldChangeMapAfterBoss()) {
        gameModeManager.generateNewEndlessMap();
      }
    }
    
    gameState.notifyListeners();
  }
  
  Enemy? _createEnemy(String type, Offset spawnPosition) {
    switch (type) {
      case "basic": return BasicEnemy(spawnPosition);
      case "speedy": return SpeedyEnemy(spawnPosition);
      case "tank": return TankEnemy(spawnPosition);
      case "flying": return FlyingEnemy(spawnPosition);
      case "elite_stun": return EliteStunEnemy(spawnPosition);
      case "lifesteal": return LifestealEnemy(spawnPosition);
      case "boss": return BossEnemy(spawnPosition);
      default: return null;
    }
  }
  
  bool _hasReachedEnd(Enemy enemy, MapData mapData) {
    return (enemy.position - mapData.path.last).distance < 1.0;
  }
  
  WaveDefinition _getCurrentWaveDefinition() {
    if (currentWave <= waveDefinitions.length) {
      return waveDefinitions[currentWave - 1];
    } else {
      // Generate dynamic waves for very high levels
      return _createEndlessWave(currentWave);
    }
  }
}

class WaveDefinition {
  final int waveNumber;
  final List<WaveEnemy> enemies;
  final bool isBossWave;
  
  int get totalEnemies => enemies.fold(0, (sum, enemy) => sum + enemy.count);
  
  WaveDefinition({
    required this.waveNumber,
    this.enemies = const [],
    this.isBossWave = false,
  });
}

class WaveEnemy {
  final String type;
  final int count;
  final double spawnInterval;
  
  int spawnedCount = 0;
  double nextSpawnTime = 0;
  
  WaveEnemy({
    required this.type,
    required this.count,
    required this.spawnInterval,
  });
}