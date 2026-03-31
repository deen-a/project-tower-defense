import 'dart:async';
import 'dart:ui' as ui;
import '../models/enemy.dart';

class WaveSystem {
  static List<Enemy> generateWave(int waveNumber, List<ui.Offset> pathPoints) {
    final enemies = <Enemy>[];
    final baseCount = 5 + (waveNumber * 2);
    
    for (int i = 0; i < baseCount; i++) {
      // Different enemy types based on wave number
      final enemyType = _getEnemyTypeForWave(waveNumber, i);
      
      switch (enemyType) {
        case 'flying':
          enemies.add(Enemy.flying(pathPoints));
          break;
        case 'tank':
          enemies.add(Enemy.tank(pathPoints));
          break;
        case 'fast':
          enemies.add(Enemy.fast(pathPoints));
          break;
        default:
          enemies.add(Enemy.basic(pathPoints));
      }
    }
    
    return enemies;
  }
  
  static String _getEnemyTypeForWave(int waveNumber, int index) {
    // Boss setiap 5 wave
    if (waveNumber % 5 == 0 && index == 0) {
      return 'tank';
    }
    
    // Flying enemies muncul setelah wave 3
    if (waveNumber >= 3 && index % 7 == 0) {
      return 'flying';
    }
    
    // Tank enemies muncul setelah wave 2
    if (waveNumber >= 2 && index % 5 == 0) {
      return 'tank';
    }
    
    // Fast enemies muncul setelah wave 1
    if (waveNumber >= 1 && index % 3 == 0) {
      return 'fast';
    }
    
    return 'basic';
  }
}

class WaveSpawner {
  final List<Enemy> enemies;
  final Duration spawnDelay;
  int _currentIndex = 0;
  Timer? _spawnTimer;
  bool isComplete = false;
  
  WaveSpawner({
    required this.enemies,
    this.spawnDelay = const Duration(milliseconds: 500),
  });
  
  void start(Function(Enemy) onSpawn, Function() onComplete) {
    if (enemies.isEmpty) {
      onComplete();
      return;
    }
    
    _spawnTimer = Timer.periodic(spawnDelay, (timer) {
      if (_currentIndex < enemies.length) {
        onSpawn(enemies[_currentIndex]);
        _currentIndex++;
      } else {
        timer.cancel();
        isComplete = true;
        onComplete();
      }
    });
  }
  
  void stop() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
  }
  
  void dispose() {
    stop();
  }
}