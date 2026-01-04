import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tower.dart';
import '../core/game_state.dart';
import '../utils/map_generator.dart';

class TowerManager {
  final List<Tower> towers = [];
  final GameState gameState;
  
  TowerManager(this.gameState);
  
  bool canPlaceTower(Tower tower, List<Offset> path, List<Offset> obstacles) {
    // Check if position is valid (not on path, not too close to other towers)
    for (var pathPoint in path) {
      if ((tower.position - pathPoint).distance < tower.placementMargin) {
        return false;
      }
    }
    
    for (var obstacle in obstacles) {
      if ((tower.position - obstacle).distance < tower.placementMargin) {
        return false;
      }
    }
    
    for (var existingTower in towers) {
      if ((tower.position - existingTower.position).distance < 
          (tower.placementMargin + existingTower.placementMargin)) {
        return false;
      }
    }
    
    return true;
  }
  
  bool placeTower(Tower tower, List<Offset> path, List<Offset> obstacles) {
    if (!canPlaceTower(tower, path, obstacles)) return false;
    if (!gameState.spendCoins(tower.cost)) return false;
    
    towers.add(tower);
    return true;
  }
  
  void updateTowers(double currentTime, List<Enemy> enemies) {
    for (var tower in towers) {
      tower.update(1/60); // Assuming 60 FPS
      
      if (tower.canFire(currentTime)) {
        final target = findTargetInRange(tower, enemies);
        if (target != null) {
          tower.fire(currentTime, target);
        }
      }
    }
  }
  
  Enemy? findTargetInRange(Tower tower, List<Enemy> enemies) {
    for (var enemy in enemies) {
      if ((tower.position - enemy.position).distance <= tower.range) {
        return enemy;
      }
    }
    return null;
  }
  
  List<Tower> getTowersInRange(Offset position, double range) {
    return towers.where((tower) => 
      (tower.position - position).distance <= range
    ).toList();
  }
}