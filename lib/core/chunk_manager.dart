import 'package:flutter/material.dart';
import 'game_constants.dart';
import '../models/tower.dart';
import '../models/enemy.dart';
import 'dart:ui' as ui;

class ChunkManager {
  static const int chunkSize = 50; // 50px = 10 meter chunks (50/5 = 10)
  
  final Map<String, Chunk> chunks = {};
  
  // Convert world position to chunk coordinates
  static (int, int) worldToChunk(ui.Offset worldPos) {
    return (
      (worldPos.dx / chunkSize).floor(),
      (worldPos.dy / chunkSize).floor(),
    );
  }
  
  // Get visible chunks in viewport
  List<Chunk> getVisibleChunks(ui.Rect viewport) {
    final visibleChunks = <Chunk>[];
    
    final startChunk = worldToChunk(viewport.topLeft);
    final endChunk = worldToChunk(viewport.bottomRight);
    
    for (int x = startChunk.$1; x <= endChunk.$1; x++) {
      for (int y = startChunk.$2; y <= endChunk.$2; y++) {
        final chunk = chunks['$x,$y'];
        if (chunk == null) {
          // Create chunk if it doesn't exist
          chunks['$x,$y'] = Chunk(x, y);
          visibleChunks.add(chunks['$x,$y']!);
        } else {
          visibleChunks.add(chunk);
        }
      }
    }
    
    return visibleChunks;
  }
  
  // Get chunks containing a point
  List<Chunk> getChunksForPosition(ui.Offset position, double radius) {
    final affectedChunks = <Chunk>[];
    final (centerChunkX, centerChunkY) = worldToChunk(position);
    
    final chunkRadius = (radius / chunkSize).ceil();
    
    for (int dx = -chunkRadius; dx <= chunkRadius; dx++) {
      for (int dy = -chunkRadius; dy <= chunkRadius; dy++) {
        final chunkKey = '${centerChunkX + dx},${centerChunkY + dy}';
        final chunk = chunks[chunkKey];
        if (chunk != null) {
          affectedChunks.add(chunk);
        }
      }
    }
    
    return affectedChunks;
  }
}

class Chunk {
  final int x;
  final int y;
  
  Chunk(this.x, this.y);
  
  ui.Rect get bounds {
    return ui.Rect.fromLTWH(
      x * ChunkManager.chunkSize.toDouble(),
      y * ChunkManager.chunkSize.toDouble(),
      ChunkManager.chunkSize.toDouble(),
      ChunkManager.chunkSize.toDouble(),
    );
  }
  
  bool contains(ui.Offset point) {
    return bounds.contains(point);
  }
}