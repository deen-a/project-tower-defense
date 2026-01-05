import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../core/game_constants.dart';
import '../utils/offset_extension.dart';

class Enemy {
  final String type;
  double health;
  final double maxHealth;
  final double walkSpeed; // meters per second
  final bool isFlying;
  final List<EnemyAbility> abilities;
  double progress; // 0-1 progress along path
  ui.Offset currentPosition;
  final List<ui.Offset> pathPoints;
  bool reachedEnd = false;
  
  Enemy({
    required this.type,
    required this.health,
    required this.maxHealth,
    required this.walkSpeed,
    required this.isFlying,
    required this.abilities,
    required this.pathPoints,
  }) : 
    progress = 0,
    currentPosition = pathPoints.first;
  
  factory Enemy.basic(List<ui.Offset> pathPoints) {
    return Enemy(
      type: 'basic',
      health: 100,
      maxHealth: 100,
      walkSpeed: 2.0,
      isFlying: false,
      abilities: [],
      pathPoints: pathPoints,
    );
  }
  
  factory Enemy.fast(List<ui.Offset> pathPoints) {
    return Enemy(
      type: 'fast',
      health: 50,
      maxHealth: 50,
      walkSpeed: 4.0,
      isFlying: false,
      abilities: [],
      pathPoints: pathPoints,
    );
  }
  
  factory Enemy.tank(List<ui.Offset> pathPoints) {
    return Enemy(
      type: 'tank',
      health: 300,
      maxHealth: 300,
      walkSpeed: 1.0,
      isFlying: false,
      abilities: [],
      pathPoints: pathPoints,
    );
  }
  
  factory Enemy.flying(List<ui.Offset> pathPoints) {
    return Enemy(
      type: 'flying',
      health: 80,
      maxHealth: 80,
      walkSpeed: 3.0,
      isFlying: true,
      abilities: [],
      pathPoints: pathPoints,
    );
  }
  
  void update(double dt) {
    if (reachedEnd) return;
    
    // Move along path
    final speed = walkSpeed * GameConstants.pixelsPerMeter * dt;
    
    if (progress < 1.0) {
      // Find current segment
      for (int i = 0; i < pathPoints.length - 1; i++) {
        final start = pathPoints[i];
        final end = pathPoints[i + 1];
        final segmentLength = (end - start).distance;
        final totalLength = _totalPathLength();
        final maxProgress = segmentLength / totalLength;
        
        if (progress < (i + 1) * maxProgress) {
          // Calculate position in this segment
          final segmentProgress = (progress - i * maxProgress) / maxProgress;
          final moveDirection = (end - start).normalized;
          
          // Update position
          currentPosition += moveDirection * speed;
          progress += speed / totalLength;
          
          // Check if reached end
          if (progress >= 1.0) {
            reachedEnd = true;
            currentPosition = pathPoints.last;
          }
          break;
        }
      }
    }
  }
  
  double _totalPathLength() {
    double length = 0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      length += (pathPoints[i + 1] - pathPoints[i]).distance;
    }
    return length;
  }
  
  bool get isAlive => health > 0;
  
  void takeDamage(double damage) {
    health -= damage;
    if (health < 0) health = 0;
  }
  
  double get remainingHealthDamage {
    // Damage ke base = sisa health / 5
    return health / 5;
  }
}

class EnemyAbility {
  final String name;
  final String description;
  final Function(Enemy) effect;
  
  EnemyAbility({
    required this.name,
    required this.description,
    required this.effect,
  });
}