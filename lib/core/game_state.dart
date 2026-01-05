import 'package:flutter/material.dart';
import '../models/tower.dart';
import '../models/enemy.dart';
import '../models/projectile.dart';
import 'chunk_manager.dart';

class GameState {
  List<Tower> towers = [];
  List<Enemy> enemies = [];
  List<Projectile> projectiles = [];
  TowerPlacement? currentPlacement;
  int coins = 2000000;
  int waveNumber = 0;
  bool isWaveActive = false;
  
  // Chunk optimization
  final ChunkManager chunkManager = ChunkManager();
  Set<String> detailedChunks = {};
  
  void updateDetailedChunks() {
    detailedChunks.clear();
    
    // Add chunks with towers
    for (var tower in towers) {
      final (chunkX, chunkY) = ChunkManager.worldToChunk(tower.pixelPosition);
      detailedChunks.add('$chunkX,$chunkY');
    }
    
    // Add chunks with enemies
    for (var enemy in enemies) {
      final (chunkX, chunkY) = ChunkManager.worldToChunk(enemy.currentPosition);
      detailedChunks.add('$chunkX,$chunkY');
    }
    
    // Add chunks with placement preview
    if (currentPlacement?.gridPosition != null) {
      final pos = currentPlacement!.pixelPosition!;
      final (chunkX, chunkY) = ChunkManager.worldToChunk(pos);
      
      // Add 3x3 area around placement
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          detailedChunks.add('${chunkX + dx},${chunkY + dy}');
        }
      }
    }
  }
  
  bool shouldRenderDetailedChunk(String chunkKey) {
    return detailedChunks.contains(chunkKey);
  }
}