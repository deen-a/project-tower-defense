import 'package:flutter/material.dart';
import 'core/game_constants.dart';
import 'core/game_state.dart';
import 'components/game_board.dart';
import 'models/tower.dart';
import 'systems/placement_system.dart';
import 'utils/offset_extension.dart';

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

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameState gameState;
  late AnimationController _animationController;
  
  // Path definition
  final List<(int, int)> pathPoints = [
    (0, 50),
    (30, 50),
    (30, 20),
    (80, 20),
    (80, 70),
    (120, 70),
    (120, 30),
    (150, 30),
  ];
  
  @override
  void initState() {
    super.initState();
    
    gameState = GameState();
    
    // Initialize animation loop
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(_updateGame);
    
    _startGameLoop();
  }
  
  void _startGameLoop() {
    _animationController.repeat();
  }
  
  void _updateGame() {
    final dt = 1 / 60; // Fixed timestep
    
    // Update enemies
    gameState.enemies.removeWhere((enemy) => !enemy.isAlive);
    
    for (var enemy in gameState.enemies) {
      enemy.update(dt);
    }
    
    // Update projectiles
    gameState.projectiles.removeWhere((proj) => !proj.isActive);
    
    for (var projectile in gameState.projectiles) {
      projectile.update(dt);
    }
    
    // Update towers
    for (var tower in gameState.towers) {
      tower.update(dt);
    }
    
    // Trigger repaint
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tower Defense - Optimized'),
      ),
      body: _buildGameUI(),
    );
  }
  
  Widget _buildGameUI() {
    return Column(
      children: [
        // HUD
        _buildHUD(),
        
        // Game Board
        Expanded(
          child: Center(
            child: GameBoard(
              gameState: gameState,
              pathPoints: pathPoints,
              onGridHover: _handleGridHover,
              onGridTap: _handleGridTap,
            ),
          ),
        ),
        
        // Tower Shop
        _buildTowerShop(),
      ],
    );
  }
  
  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coins: ${gameState.coins}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Wave: ${gameState.waveNumber}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                gameState.currentPlacement != null
                    ? 'Placing: ${GameConstants.towerSpecs[gameState.currentPlacement!.type]!.name}'
                    : 'Select a tower',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                'Enemies: ${gameState.enemies.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          
          ElevatedButton(
            onPressed: _startWave,
            style: ElevatedButton.styleFrom(
              backgroundColor: gameState.isWaveActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(gameState.isWaveActive ? 'Wave Active' : 'Start Wave'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTowerShop() {
    return Container(
      height: 100,
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text(
            'TOWER SHOP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTowerButton('basic'),
                _buildTowerButton('burst'),
                _buildTowerButton('railgun'),
                _buildTowerButton('flamethrower'),
                _buildCancelButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTowerButton(String type) {
    final specs = GameConstants.towerSpecs[type]!;
    final isSelected = gameState.currentPlacement?.type == type;
    final canAfford = gameState.coins >= specs.cost;
    
    return GestureDetector(
      onTap: canAfford
          ? () {
              setState(() {
                gameState.currentPlacement = TowerPlacement(type: type);
              });
            }
          : null,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: specs.color.withOpacity(canAfford ? 0.9 : 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(specs.icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              specs.name.split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${specs.cost}',
              style: TextStyle(
                color: canAfford ? Colors.yellow : Colors.red[300],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          gameState.currentPlacement = null;
        });
      },
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: gameState.currentPlacement == null ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, color: Colors.white, size: 20),
            SizedBox(height: 2),
            Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleGridHover((int, int)? gridPos) {
    if (gridPos == null || gameState.currentPlacement == null) return;
    
    setState(() {
      final pixelPos = GameConstants.gridToPixel(gridPos.$1, gridPos.$2);
      final isValid = PlacementSystem.isValidPosition(
        pixelPos,
        gameState.currentPlacement!.type,
        gameState.towers,
        pathPoints,
      );
      
      gameState.currentPlacement = TowerPlacement(
        type: gameState.currentPlacement!.type,
        gridPosition: gridPos,
        isValid: isValid,
      );
    });
  }
  
  void _handleGridTap((int, int)? gridPos) {
    if (gridPos == null || gameState.currentPlacement == null || !gameState.currentPlacement!.isValid) {
      return;
    }
    
    final specs = GameConstants.towerSpecs[gameState.currentPlacement!.type]!;
    
    if (gameState.coins >= specs.cost) {
      setState(() {
        gameState.towers.add(Tower(
          gridPosition: gridPos,
          type: gameState.currentPlacement!.type,
        ));
        gameState.coins -= specs.cost;
        gameState.currentPlacement = null;
      });
    }
  }
  
  void _startWave() {
    if (gameState.isWaveActive) return;
    
    setState(() {
      gameState.isWaveActive = true;
      gameState.waveNumber++;
      
      // Spawn enemies based on wave number
      // This is a simple implementation
      for (int i = 0; i < gameState.waveNumber * 5; i++) {
        // Convert path points from grid to pixel
        final pixelPathPoints = pathPoints.map((point) {
          return GameConstants.gridToPixel(point.$1, point.$2);
        }).toList();
        
        // Create enemy
        // You'll need to add more sophisticated enemy creation here
        // gameState.enemies.add(Enemy(...));
      }
    });
  }
}