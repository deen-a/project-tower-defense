import 'dart:math';
import 'package:flutter/material.dart';

class MapGenerator {
  static const int gridWidth = 15;
  static const int gridHeight = 10;
  static const double cellSize = 50.0;
  
  static MapData generateRandomMap({
    String environment = 'forest',
    bool hasFlyingObstacles = false,
  }) {
    final random = Random();
    final path = <Offset>[];
    final obstacles = <Offset>[];
    final flyingObstacles = <Offset>[];
    
    // Simple random path generation
    int startY = random.nextInt(gridHeight);
    path.add(Offset(0, startY.toDouble()));
    
    int x = 1;
    int y = startY;
    
    while (x < gridWidth - 1) {
      // Random direction: right, up-right, down-right
      int direction = random.nextInt(3);
      switch (direction) {
        case 0: // right
          break;
        case 1: // up-right
          y = max(0, y - 1);
          break;
        case 2: // down-right
          y = min(gridHeight - 1, y + 1);
          break;
      }
      
      path.add(Offset(x.toDouble(), y.toDouble()));
      x++;
    }
    
    // Add end point
    path.add(Offset((gridWidth - 1).toDouble(), y.toDouble()));
    
    // Generate some random obstacles (not on path)
    for (int i = 0; i < 10; i++) {
      final obstacle = Offset(
        random.nextInt(gridWidth).toDouble(),
        random.nextInt(gridHeight).toDouble(),
      );
      
      bool isValid = true;
      for (var pathPoint in path) {
        if ((obstacle - pathPoint).distance < 1.5) {
          isValid = false;
          break;
        }
      }
      
      if (isValid && obstacles.length < 8) {
        obstacles.add(obstacle);
      }
    }
    
    // Generate flying obstacles
    if (hasFlyingObstacles) {
      for (int i = 0; i < 8; i++) {
        final obstacle = Offset(
          random.nextInt(gridWidth).toDouble(),
          random.nextInt(gridHeight).toDouble(),
        );
        
        bool isValid = true;
        for (var pathPoint in path) {
          if ((obstacle - pathPoint).distance < 2.0) {
            isValid = false;
            break;
          }
        }
        
        if (isValid && flyingObstacles.length < 5) {
          flyingObstacles.add(obstacle);
        }
      }
    }
    
    return MapData(
      path: path,
      obstacles: obstacles,
      flyingObstacles: flyingObstacles,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      cellSize: cellSize,
      environment: environment,
    );
  }
}

class MapData {
  final List<Offset> path;
  final List<Offset> obstacles;
  final List<Offset> flyingObstacles;
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  final String environment;
  
  MapData({
    required this.path,
    required this.obstacles,
    required this.flyingObstacles,
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
    required this.environment,
  });
}