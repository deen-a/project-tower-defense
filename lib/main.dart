import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'core/game_constants.dart';
import 'core/game_state.dart';
import 'components/game_board.dart';
import 'models/tower.dart';
import 'models/enemy.dart';
import 'systems/placement_system.dart';
import 'systems/wave_system.dart';
import 'systems/game_loop.dart'; // IMPORT BARU

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
  late GameLoop gameLoop; // TAMBAH INI
  
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
  
  // Untuk hover detection
  GlobalKey _boardKey = GlobalKey();
  (int, int)? _hoverGridPosition;
  
  @override
  void initState() {
    super.initState();
    
    gameState = GameState();
    gameLoop = GameLoop(gameState); // INIT GAME LOOP
    gameLoop.start(); // START GAME LOOP
    
    // Hapus AnimationController lama, ganti dengan GameLoop
  }
  
  @override
  void dispose() {
    gameLoop.dispose(); // DISPOSE GAME LOOP
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
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 16), (_) => gameLoop.frameCount),
      builder: (context, snapshot) {
        return Column(
          children: [
            // HUD
            _buildHUD(),
            
            // Game Board dengan MouseRegion
            Expanded(
              child: Center(
                child: MouseRegion(
                  onHover: _handleMouseHover,
                  child: GestureDetector(
                    onTapDown: _handleBoardTap,
                    child: GameBoard(
                      key: _boardKey,
                      gameState: gameState,
                      pathPoints: pathPoints,
                      onGridHover: _handleGridHover,
                      onGridTap: _handleGridTap,
                    ),
                  ),
                ),
              ),
            ),
            
            // Tower Shop
            _buildTowerShop(),
          ],
        );
      }
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
                'Base HP: ${gameState.baseHealth.toStringAsFixed(1)}/${gameState.maxBaseHealth}',
                style: TextStyle(
                  color: gameState.baseHealth < 30 ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
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
                'Wave: ${gameState.waveNumber} | Enemies: ${gameState.enemies.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          
          ElevatedButton(
            onPressed: gameState.isWaveActive ? null : _startWave,
            style: ElevatedButton.styleFrom(
              backgroundColor: gameState.isWaveActive ? Colors.grey : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(gameState.isWaveActive ? 'Wave Active' : 'Start Wave ${gameState.waveNumber + 1}'),
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
                _hoverGridPosition = null;
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
          _hoverGridPosition = null;
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
  
  void _handleMouseHover(PointerEvent event) {
    if (gameState.currentPlacement == null) return;
    
    final renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPos = renderBox.globalToLocal(event.position);
    final size = renderBox.size;
    
    // Check if within bounds
    if (localPos.dx < 0 || localPos.dy < 0 || 
        localPos.dx > size.width || localPos.dy > size.height) {
      setState(() {
        _hoverGridPosition = null;
      });
      return;
    }
    
    // Convert to grid coordinates
    final unscaledX = localPos.dx; // Sudah dalam pixel game
    final unscaledY = localPos.dy;
    
    final gridX = (unscaledX / GameConstants.pixelsPerMeter).floor();
    final gridY = (unscaledY / GameConstants.pixelsPerMeter).floor();
    
    // Clamp to board boundaries
    final clampedX = gridX.clamp(0, GameConstants.boardWidthMeters - 1);
    final clampedY = gridY.clamp(0, GameConstants.boardHeightMeters - 1);
    
    setState(() {
      _hoverGridPosition = (clampedX, clampedY);
      _handleGridHover(_hoverGridPosition);
    });
  }
  
  void _handleBoardTap(TapDownDetails details) {
    if (_hoverGridPosition != null) {
      _handleGridTap(_hoverGridPosition);
    }
  }
  
  void _handleGridHover((int, int)? gridPos) {
    if (gridPos == null || gameState.currentPlacement == null) return;
    
    final pixelPos = GameConstants.gridToPixel(gridPos.$1, gridPos.$2);
    final isValid = PlacementSystem.isValidPosition(
      pixelPos,
      gameState.currentPlacement!.type,
      gameState.towers,
      pathPoints,
    );
    
    setState(() {
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
        _hoverGridPosition = null;
      });
    }
  }
  
  void _startWave() {
    if (gameState.isWaveActive) return;
    
    setState(() {
      gameState.isWaveActive = true;
      gameState.waveNumber++;
      
      // Convert path points from grid to pixel
      final pixelPathPoints = pathPoints.map((point) {
        return GameConstants.gridToPixel(point.$1, point.$2);
      }).toList();
      
      // Generate enemies for this wave
      final newEnemies = WaveSystem.generateWave(gameState.waveNumber, pixelPathPoints);
      gameState.enemies.addAll(newEnemies);
    });
  }
}