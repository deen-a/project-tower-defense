import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../core/game_constants.dart';
import '../core/chunk_manager.dart';
import '../models/tower.dart';
import '../models/enemy.dart';
import '../models/projectile.dart';
import '../utils/offset_extension.dart';

class RenderingSystem {
  static final Random _random = Random();
  
  static void drawChunkBackground(
    Canvas canvas, 
    ui.Rect bounds, 
    bool isDetailed,
  ) {
    if (isDetailed) {
      _drawDetailedChunk(canvas, bounds);
    } else {
      _drawSimpleChunk(canvas, bounds);
    }
  }
  
  static void _drawDetailedChunk(Canvas canvas, ui.Rect bounds) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFF2D5A27);
    canvas.drawRect(bounds, bgPaint);
    
    // Fine grid (1 meter)
    final gridPaint = Paint()
      ..color = const Color(0xFF3A6B33).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    final startX = bounds.left;
    final endX = bounds.right;
    final startY = bounds.top;
    final endY = bounds.bottom;
    
    // Vertical lines
    for (double x = startX; x <= endX; x += GameConstants.pixelsPerMeter) {
      canvas.drawLine(ui.Offset(x, startY), ui.Offset(x, endY), gridPaint);
    }
    
    // Horizontal lines
    for (double y = startY; y <= endY; y += GameConstants.pixelsPerMeter) {
      canvas.drawLine(ui.Offset(startX, y), ui.Offset(endX, y), gridPaint);
    }
    
    // Chunk border
    final borderPaint = Paint()
      ..color = const Color(0xFF4A7A43).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(bounds, borderPaint);
  }
  
  static void _drawSimpleChunk(Canvas canvas, ui.Rect bounds) {
    // Simple background
    final chunkPaint = Paint()..color = const Color(0xFF1E3A1F);
    canvas.drawRect(bounds, chunkPaint);
    
    // Very subtle pattern
    final patternPaint = Paint()
      ..color = const Color(0xFF2D5A27).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    // Major grid lines every 10 meters
    for (double x = bounds.left; x <= bounds.right; x += GameConstants.pixelsPerMeter * 10) {
      canvas.drawLine(ui.Offset(x, bounds.top), ui.Offset(x, bounds.bottom), patternPaint);
    }
    for (double y = bounds.top; y <= bounds.bottom; y += GameConstants.pixelsPerMeter * 10) {
      canvas.drawLine(ui.Offset(bounds.left, y), ui.Offset(bounds.right, y), patternPaint);
    }
  }
  
  static void drawPath(Canvas canvas, List<(int, int)> pathPoints) {
    final pathWidthPixels = GameConstants.pathWidthPixels;
    
    // Draw path segments
    final pathPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidthPixels;
    
    final borderPaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = GameConstants.gridToPixel(pathPoints[i].$1, pathPoints[i].$2);
      final end = GameConstants.gridToPixel(pathPoints[i + 1].$1, pathPoints[i + 1].$2);
      
      canvas.drawLine(start, end, pathPaint);
      canvas.drawLine(start, end, borderPaint);
    }
    
    // Draw start/end markers
    final startPoint = GameConstants.gridToPixel(pathPoints.first.$1, pathPoints.first.$2);
    final endPoint = GameConstants.gridToPixel(pathPoints.last.$1, pathPoints.last.$2);
    
    canvas.drawCircle(startPoint, 8, Paint()..color = Colors.red);
    canvas.drawCircle(endPoint, 8, Paint()..color = Colors.blue);
  }
  
  static void drawTower(
    Canvas canvas, 
    Tower tower, 
    bool isSelected, 
    bool showRange,
  ) {
    final specs = tower.specs;
    final position = tower.pixelPosition;
    
    // Range indicator
    if (showRange) {
      final rangePaint = Paint()
        ..color = specs.color.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, specs.rangePixels, rangePaint);
      
      if (specs.secondaryRangePixels != null) {
        final secondaryPaint = Paint()
          ..color = specs.color.withOpacity(0.04)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(position, specs.secondaryRangePixels!, secondaryPaint);
      }
    }
    
    // Tower base
    final basePaint = Paint()..color = Colors.grey[900]!;
    canvas.drawCircle(position, GameConstants.metersToPixels(1.8), basePaint);
    
    // Tower body
    final towerPaint = Paint()..color = isSelected ? specs.color.withOpacity(0.8) : specs.color;
    canvas.drawCircle(position, GameConstants.metersToPixels(1.2), towerPaint);
    
    // Selection ring
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, GameConstants.metersToPixels(2.0), selectionPaint);
    }
  }
  
  static void drawEnemy(Canvas canvas, Enemy enemy) {
    final position = enemy.currentPosition;
    final healthPercent = enemy.health / enemy.maxHealth;
    
    // Enemy body
    final bodyColor = _getEnemyColor(enemy.type);
    final bodyPaint = Paint()..color = bodyColor;
    
    final size = enemy.isFlying 
        ? GameConstants.metersToPixels(1.5)
        : GameConstants.metersToPixels(2.0);
    
    canvas.drawCircle(position, size, bodyPaint);
    
    // Health bar
    final healthBarWidth = size * 2;
    final healthBarHeight = 3;
    final healthBarY = position.dy - size - 5;
    
    // Background
    canvas.drawRect(
      ui.Rect.fromCenter(
        center: ui.Offset(position.dx, healthBarY),
        width: healthBarWidth,
        height: healthBarHeight.toDouble(),
      ),
      Paint()..color = Colors.red[800]!,
    );
    
    // Current health
    canvas.drawRect(
      ui.Rect.fromCenter(
        center: ui.Offset(position.dx - healthBarWidth * (1 - healthPercent) / 2, healthBarY),
        width: healthBarWidth * healthPercent,
        height: healthBarHeight.toDouble(),
      ),
      Paint()..color = Colors.green,
    );
  }
  
  static void drawProjectile(Canvas canvas, Projectile projectile) {
    final pos = projectile.currentPosition;
    
    switch (projectile.type) {
      case ProjectileType.basic:
      case ProjectileType.rapid:
        canvas.drawCircle(
          pos,
          projectile.width / 2,
          Paint()..color = projectile.color,
        );
        break;
        
      case ProjectileType.laser:
        // Draw laser beam
        final direction = (projectile.target.currentPosition - pos).normalized;
        final length = projectile.height;
        final endPos = pos + direction * length;
        
        final laserPaint = Paint()
          ..color = projectile.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = projectile.width
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(pos, endPos, laserPaint);
        break;
        
      case ProjectileType.flame:
        // Draw flame particles
        final particleCount = 5;
        for (int i = 0; i < particleCount; i++) {
          final offset = ui.Offset(
            pos.dx + (_random.nextDouble() * 8 - 4), // PERBAIKAN DI SINI
            pos.dy + (_random.nextDouble() * 8 - 4), // PERBAIKAN DI SINI
          );
          
          canvas.drawCircle(
            offset,
            projectile.width / 3,
            Paint()
              ..color = projectile.color.withOpacity(0.7)
              ..blendMode = BlendMode.plus,
          );
        }
        break;
    }
  }
  
  static Color _getEnemyColor(String type) {
    switch (type) {
      case 'basic': return Colors.green;
      case 'tank': return Colors.grey;
      case 'fast': return Colors.yellow;
      case 'flying': return Colors.lightBlue;
      case 'boss': return Colors.purple;
      default: return Colors.red;
    }
  }
}