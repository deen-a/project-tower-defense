import 'dart:ui' as ui;
import '../models/enemy.dart';

class WaveSystem {
  static List<Enemy> generateWave(int waveNumber, List<ui.Offset> pathPoints) {
    final enemies = <Enemy>[];
    final baseCount = 5 + waveNumber * 2;
    
    for (int i = 0; i < baseCount; i++) {
      // Different enemy types based on wave number
      if (waveNumber >= 5 && i % 5 == 0) {
        enemies.add(Enemy.flying(pathPoints));
      } else if (waveNumber >= 3 && i % 3 == 0) {
        enemies.add(Enemy.tank(pathPoints));
      } else if (waveNumber >= 2 && i % 2 == 0) {
        enemies.add(Enemy.fast(pathPoints));
      } else {
        enemies.add(Enemy.basic(pathPoints));
      }
    }
    
    // Spawn with delay
    for (int i = 0; i < enemies.length; i++) {
      // You can add delay logic here
    }
    
    return enemies;
  }
}