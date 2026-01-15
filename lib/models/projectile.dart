import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'enemy.dart';
import '../utils/offset_extension.dart';

enum ProjectileType {
  basic,     // Bulat kecil - untuk basic tower
  rapid,     // Bulat cepat - untuk rapid tower
  laser,     // Kotak panjang - untuk sniper
  flame,     // Particle sistem - untuk flamethrower
}

class Projectile {
  final ProjectileType type;
  final double damage;
  final double speed;
  final ui.Offset startPosition;
  final Enemy target;
  final double splashRadius;
  final Color color;
  
  ui.Offset currentPosition;
  bool isActive = true;
  
  Projectile({
    required this.type,
    required this.damage,
    required this.speed,
    required this.startPosition,
    required this.target,
    this.splashRadius = 0,
    required this.color,
  }) : currentPosition = startPosition;
  
  void update(double dt) {
    if (!isActive) return;
    if (!target.isAlive) {
      isActive = false;
      return;
    }
    
    // Move toward target
    final direction = (target.currentPosition - currentPosition).normalized;
    final movement = direction * speed * dt;
    currentPosition += movement;
    
    // Check hit - lebih akurat
    final distanceToTarget = (target.currentPosition - currentPosition).distance;
    final hitThreshold = type == ProjectileType.laser ? 30 : 15; // Laser punya threshold lebih besar
    
    if (distanceToTarget < hitThreshold) {
      isActive = false;
    }
    
    // Untuk laser, langsung hit jika dalam line of sight
    if (type == ProjectileType.laser) {
      final distanceTraveled = (currentPosition - startPosition).distance;
      final distanceToTargetFromStart = (target.currentPosition - startPosition).distance;
      
      if (distanceTraveled >= distanceToTargetFromStart) {
        isActive = false;
      }
    }
  }
  
  // Visual properties based on type
  double get width {
    switch (type) {
      case ProjectileType.basic:
        return 4;
      case ProjectileType.rapid:
        return 3;
      case ProjectileType.laser:
        return 8; // Lebar untuk laser
      case ProjectileType.flame:
        return 6;
    }
  }
  
  double get height {
    switch (type) {
      case ProjectileType.basic:
        return 4;
      case ProjectileType.rapid:
        return 3;
      case ProjectileType.laser:
        return (target.currentPosition - currentPosition).distance; // Panjang sesuai jarak ke target
      case ProjectileType.flame:
        return 6;
    }
  }
}