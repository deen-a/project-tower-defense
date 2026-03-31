import 'package:flutter/material.dart';
import '../utils/map_generator.dart';
import '../managers/tower_manager.dart';
import '../models/tower.dart';

class GameBoard extends StatelessWidget {
  final MapData mapData;
  final TowerManager towerManager;
  final Function(Tower) onTowerPlaced;
  
  const GameBoard({
    super.key,
    required this.mapData,
    required this.towerManager,
    required this.onTowerPlaced,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: CustomPaint(
        size: Size(
          mapData.gridWidth * mapData.cellSize,
          mapData.gridHeight * mapData.cellSize,
        ),
        painter: GameBoardPainter(
          mapData: mapData,
          towerManager: towerManager,
        ),
      ),
    );
  }
}

class GameBoardPainter extends CustomPainter {
  final MapData mapData;
  final TowerManager towerManager;
  
  GameBoardPainter({
    required this.mapData,
    required this.towerManager,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int x = 0; x <= mapData.gridWidth; x++) {
      canvas.drawLine(
        Offset(x * mapData.cellSize, 0),
        Offset(x * mapData.cellSize, size.height),
        gridPaint,
      );
    }
    
    for (int y = 0; y <= mapData.gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * mapData.cellSize),
        Offset(size.width, y * mapData.cellSize),
        gridPaint,
      );
    }
    
    // Draw path
    final pathPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = mapData.cellSize * 0.8;
    
    for (int i = 0; i < mapData.path.length - 1; i++) {
      canvas.drawLine(
        Offset(
          mapData.path[i].dx * mapData.cellSize + mapData.cellSize / 2,
          mapData.path[i].dy * mapData.cellSize + mapData.cellSize / 2,
        ),
        Offset(
          mapData.path[i + 1].dx * mapData.cellSize + mapData.cellSize / 2,
          mapData.path[i + 1].dy * mapData.cellSize + mapData.cellSize / 2,
        ),
        pathPaint,
      );
    }
    
    // Draw obstacles
    final obstaclePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;
    
    for (var obstacle in mapData.obstacles) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(
            obstacle.dx * mapData.cellSize + mapData.cellSize / 2,
            obstacle.dy * mapData.cellSize + mapData.cellSize / 2,
          ),
          width: mapData.cellSize * 0.8,
          height: mapData.cellSize * 0.8,
        ),
        obstaclePaint,
      );
    }
    
    // Draw flying obstacles
    final flyingObstaclePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;
    
    for (var obstacle in mapData.flyingObstacles) {
      canvas.drawCircle(
        Offset(
          obstacle.dx * mapData.cellSize + mapData.cellSize / 2,
          obstacle.dy * mapData.cellSize + mapData.cellSize / 2,
        ),
        mapData.cellSize * 0.4,
        flyingObstaclePaint,
      );
    }
    
    // Draw towers
    for (var tower in towerManager.towers) {
      final towerPaint = Paint()
        ..color = _getTowerColor(tower.type)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          tower.position.dx * mapData.cellSize + mapData.cellSize / 2,
          tower.position.dy * mapData.cellSize + mapData.cellSize / 2,
        ),
        mapData.cellSize * 0.3,
        towerPaint,
      );
      
      // Draw range circle
      final rangePaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          tower.position.dx * mapData.cellSize + mapData.cellSize / 2,
          tower.position.dy * mapData.cellSize + mapData.cellSize / 2,
        ),
        tower.range,
        rangePaint,
      );
    }
  }
  
  Color _getTowerColor(String type) {
    switch (type) {
      case 'basic': return Colors.blue;
      case 'burst': return Colors.red;
      case 'railgun': return Colors.purple;
      case 'flamethrower': return Colors.orange;
      default: return Colors.grey;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}