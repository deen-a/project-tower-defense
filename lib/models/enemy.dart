import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../core/game_constants.dart';
import '../utils/offset_extension.dart'; // Import extension

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
  
  void update(double dt) {
    // Move along path
    final speed = walkSpeed * GameConstants.pixelsPerMeter * dt;
    
    if (progress < 1.0) {
      // Find current segment
      for (int i = 0; i < pathPoints.length - 1; i++) {
        final start = pathPoints[i];
        final end = pathPoints[i + 1];
        final segmentLength = (end - start).distance;
        final maxProgress = segmentLength / _totalPathLength();
        
        if (progress < (i + 1) * maxProgress) {
          // Calculate position in this segment
          final segmentProgress = (progress - i * maxProgress) / maxProgress;
          final targetPos = ui.Offset.lerp(start, end, segmentProgress)!;
          final moveDirection = (end - start).normalized;
          final newPos = currentPosition + moveDirection * speed;
          
          currentPosition = newPos;
          progress += speed / _totalPathLength();
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
}

enum EnemyType {
  basic,
  tank,
  fast,
  flying,
  boss,
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