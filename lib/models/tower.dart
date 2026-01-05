import 'package:flutter/material.dart';
import '../core/game_constants.dart';
import 'dart:ui' as ui;

class Tower {
  final (int, int) gridPosition;
  final String type;
  final TowerSpecs specs;
  double fireCooldown = 0;
  
  Tower({
    required this.gridPosition,
    required this.type,
  }) : specs = GameConstants.towerSpecs[type]!;
  
  ui.Offset get pixelPosition {
    return GameConstants.gridToPixel(gridPosition.$1, gridPosition.$2);
  }
  
  bool canFire() => fireCooldown <= 0;
  
  void update(double dt) {
    if (fireCooldown > 0) {
      fireCooldown -= dt;
    }
  }
  
  void resetCooldown() {
    fireCooldown = 1.0 / specs.fireRate;
  }
}

class TowerPlacement {
  final String type;
  final (int, int)? gridPosition;
  final bool isValid;
  
  TowerPlacement({
    required this.type,
    this.gridPosition,
    this.isValid = false,
  });
  
  ui.Offset? get pixelPosition {
    if (gridPosition == null) return null;
    return GameConstants.gridToPixel(gridPosition!.$1, gridPosition!.$2);
  }
}