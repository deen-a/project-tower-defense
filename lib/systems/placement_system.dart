import 'package:flutter/material.dart';
import '../core/game_constants.dart';
import '../models/tower.dart';
import '../utils/offset_extension.dart';
import 'dart:ui' as ui;

class PlacementSystem {
  static bool isValidPosition(
    ui.Offset pixelPosition,
    String towerType,
    List<Tower> towers,
    List<(int, int)> pathPoints,
  ) {
    final specs = GameConstants.towerSpecs[towerType]!;
    final marginPixels = specs.placementMarginPixels;
    
    // 1. Check distance to path
    final totalPathWidth = GameConstants.pathWidthPixels + GameConstants.pathMarginPixels;
    
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = GameConstants.gridToPixel(pathPoints[i].$1, pathPoints[i].$2);
      final end = GameConstants.gridToPixel(pathPoints[i + 1].$1, pathPoints[i + 1].$2);
      
      if (_isPointNearLine(pixelPosition, start, end, totalPathWidth / 2)) {
        return false;
      }
    }
    
    // 2. Check distance to existing towers
    for (var tower in towers) {
      final towerPos = tower.pixelPosition;
      final distance = (towerPos - pixelPosition).distance;
      final requiredDistance = marginPixels + 
          GameConstants.towerSpecs[tower.type]!.placementMarginPixels;
      
      if (distance < requiredDistance) {
        return false;
      }
    }
    
    // 3. Check boundaries
    final (gridX, gridY) = GameConstants.pixelToGrid(pixelPosition);
    
    if (gridX < 0 || gridX >= GameConstants.boardWidthMeters ||
        gridY < 0 || gridY >= GameConstants.boardHeightMeters) {
      return false;
    }
    
    return true;
  }
  
  static bool _isPointNearLine(ui.Offset point, ui.Offset lineStart, ui.Offset lineEnd, double threshold) {
    final lineLength = (lineEnd - lineStart).distance;
    if (lineLength == 0) return (point - lineStart).distance <= threshold;
    
    final lineVec = lineEnd - lineStart;
    final pointVec = point - lineStart;
    final t = (pointVec.dx * lineVec.dx + pointVec.dy * lineVec.dy) / (lineLength * lineLength);
    
    if (t < 0) return (point - lineStart).distance <= threshold;
    if (t > 1) return (point - lineEnd).distance <= threshold;
    
    final closestPoint = lineStart + ui.Offset(lineVec.dx * t, lineVec.dy * t);
    return (point - closestPoint).distance <= threshold;
  }
}