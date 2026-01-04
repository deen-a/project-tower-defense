import 'package:flutter/material.dart';

void main() {
  runApp(const TowerDefenseGame());
}

class TowerDefenseGame extends StatelessWidget {
  const TowerDefenseGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Defense',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Offset> towers = [];
  int coins = 2000000;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tower Defense'),
      ),
      body: Column(
        children: [
          // Game Board
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                
                setState(() {
                  towers.add(localPosition);
                  coins -= 75; // Cost untuk basic tower
                });
              },
              child: Container(
                color: Colors.green[100],
                child: CustomPaint(
                  painter: GameBoardPainter(towers: towers),
                ),
              ),
            ),
          ),
          
          // HUD
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coins: $coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      coins += 100;
                    });
                  },
                  child: const Text('Add Coins (Test)'),
                ),
              ],
            ),
          ),
          
          // Tower Shop
          Container(
            height: 100,
            color: Colors.grey[900],
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTowerButton('Basic Tower', Colors.blue, 75),
                _buildTowerButton('Rapid Tower', Colors.red, 125),
                _buildTowerButton('Sniper Tower', Colors.purple, 225),
                _buildTowerButton('Flamethrower', Colors.orange, 150),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTowerButton(String name, Color color, int cost) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: coins >= cost ? () {
            // Tower selection logic here
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: const Icon(Icons.location_city, color: Colors.white),
        ),
        Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          '$cost',
          style: TextStyle(
            color: coins >= cost ? Colors.yellow : Colors.red,
          ),
        ),
      ],
    );
  }
}

class GameBoardPainter extends CustomPainter {
  final List<Offset> towers;
  
  GameBoardPainter({required this.towers});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grass background
    final grassPaint = Paint()..color = Colors.green[100]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);
    
    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Draw path (simple straight line)
    final pathPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;
    
    final pathRect = Rect.fromLTWH(
      gridSize * 2, // Start at grid position 2
      size.height / 2 - gridSize,
      size.width - gridSize * 4, // Width of path
      gridSize * 2, // Height of path
    );
    canvas.drawRect(pathRect, pathPaint);
    
    // Draw towers
    for (var tower in towers) {
      final towerPaint = Paint()..color = Colors.blue;
      canvas.drawCircle(
        tower,
        20,
        towerPaint,
      );
      
      // Draw range indicator
      final rangePaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tower, 60, rangePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}