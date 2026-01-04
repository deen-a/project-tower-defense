import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../managers/tower_manager.dart';
import '../utils/map_generator.dart';
import '../models/tower.dart';

class TowerShop extends StatelessWidget {
  final GameState gameState;
  final TowerManager towerManager;
  final MapData mapData;
  final VoidCallback onTowerPlaced;

  const TowerShop({
    super.key,
    required this.gameState,
    required this.towerManager,
    required this.mapData,
    required this.onTowerPlaced,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.black54,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTowerButton(
            context,
            'Basic Tower',
            Colors.blue,
            75,
            () => _placeTower(context, BasicTower(Offset.zero)),
          ),
          _buildTowerButton(
            context,
            'Burst Tower', 
            Colors.red,
            125,
            () => _placeTower(context, BurstTower(Offset.zero)),
          ),
          _buildTowerButton(
            context,
            'Railgun Tower',
            Colors.purple,
            225,
            () => _placeTower(context, RailgunTower(Offset.zero)),
          ),
          _buildTowerButton(
            context,
            'Flamethrower',
            Colors.orange,
            150,
            () => _placeTower(context, FlamethrowerTower(Offset.zero)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTowerButton(BuildContext context, String name, Color color, int cost, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: gameState.coins >= cost ? Colors.white : Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        Text(
          '$cost',
          style: TextStyle(
            color: gameState.coins >= cost ? Colors.yellow : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  void _placeTower(BuildContext context, Tower tower) {
    // For now, just place at a fixed position for testing
    final testPosition = Offset(2.0, 2.0);
    final randomPosition = _findValidPosition();
    
    if (randomPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid position found!')),
      );
      return;
    }


    Tower newTower;
    switch (tower.type) {
      case 'basic':
        newTower = BasicTower(testPosition);
        break;
      case 'burst':
        newTower = BurstTower(testPosition);
        break;
      case 'railgun':
        newTower = RailgunTower(testPosition);
        break;
      case 'flamethrower':
        newTower = FlamethrowerTower(testPosition);
        break;
      default:
        return;
    }
    
    if (towerManager.placeTower(newTower, mapData.path, mapData.obstacles)) {
      // Tower placed successfully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tower.type} placed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place tower here!')),
      );
    }
  }

  Offset? _findValidPosition() {
    // Simple method to find a valid position for testing
    for (int x = 0; x < mapData.gridWidth; x++) {
      for (int y = 0; y < mapData.gridHeight; y++) {
        final position = Offset(x.toDouble(), y.toDouble());
        final testTower = BasicTower(position);
        
        if (towerManager.canPlaceTower(testTower, mapData.path, mapData.obstacles)) {
          return position;
        }
      }
    }
    return null;
  }
}