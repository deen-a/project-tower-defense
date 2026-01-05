import 'dart:math';
import 'package:flutter/material.dart';
import 'game_constants.dart';
import '../main.dart'; // Import Tower class

class ChunkManager {
  static const int chunkSize = 50; // 50px = 10 meter chunks (50/5 = 10)
  
  final Map<String, Chunk> chunks = {};
  final Set<String> activeChunks = {};
  
  // Convert world position to chunk coordinates
  static (int, int) worldToChunk(Offset worldPos) {
    return (
      (worldPos.dx / chunkSize).floor(),
      (worldPos.dy / chunkSize).floor(),
    );
  }
  
  // Get chunk from world position
  Chunk? getChunkAt(Offset worldPos) {
    final (chunkX, chunkY) = worldToChunk(worldPos);
    return chunks['$chunkX,$chunkY'];
  }
  
  // Get or create chunk
  Chunk getOrCreateChunkAt(Offset worldPos) {
    final (chunkX, chunkY) = worldToChunk(worldPos);
    final key = '$chunkX,$chunkY';
    
    return chunks.putIfAbsent(key, () => Chunk(chunkX, chunkY));
  }
  
  // Update chunk activity based on objects
  void updateChunkActivity(List<Tower> towers, List<(int, int)> pathPoints) {
    activeChunks.clear();
    
    // Mark chunks with towers as active
    for (var tower in towers) {
      final (chunkX, chunkY) = worldToChunk(tower.pixelPosition);
      activeChunks.add('$chunkX,$chunkY');
      
      // Also mark neighboring chunks for range effects
      final range = GameConstants.towerSpecs[tower.type]!.rangePixels;
      final neighborRadius = (range / chunkSize).ceil();
      
      for (int dx = -neighborRadius; dx <= neighborRadius; dx++) {
        for (int dy = -neighborRadius; dy <= neighborRadius; dy++) {
          activeChunks.add('${chunkX + dx},${chunkY + dy}');
        }
      }
    }
    
    // Mark chunks with path as active
    for (var point in pathPoints) {
      final worldPos = GameConstants.gridToPixel(point.$1, point.$2);
      final (chunkX, chunkY) = worldToChunk(worldPos);
      activeChunks.add('$chunkX,$chunkY');
    }
  }
  
  // Get visible chunks in viewport
  List<Chunk> getVisibleChunks(Rect viewport) {
    final visibleChunks = <Chunk>[];
    
    final startChunk = worldToChunk(viewport.topLeft);
    final endChunk = worldToChunk(viewport.bottomRight);
    
    for (int x = startChunk.$1; x <= endChunk.$1; x++) {
      for (int y = startChunk.$2; y <= endChunk.$2; y++) {
        final chunk = chunks['$x,$y'];
        if (chunk != null) {
          visibleChunks.add(chunk);
        }
      }
    }
    
    return visibleChunks;
  }
}

class Chunk {
  final int x;
  final int y;
  bool isActive = false;
  
  Chunk(this.x, this.y);
  
  Rect get bounds {
    return Rect.fromLTWH(
      x * ChunkManager.chunkSize.toDouble(),
      y * ChunkManager.chunkSize.toDouble(),
      ChunkManager.chunkSize.toDouble(),
      ChunkManager.chunkSize.toDouble(),
    );
  }
  
  bool contains(Offset point) {
    return bounds.contains(point);
  }
}