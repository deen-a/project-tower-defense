import 'package:flutter/material.dart';
import 'core/game_state.dart';
import 'utils/map_generator.dart';
import 'managers/tower_manager.dart';
import 'widgets/game_board.dart';
import 'widgets/hud.dart';
import 'widgets/tower_shop.dart';

void main() {
  runApp(const TowerDefenseGame());
}

class TowerDefenseGame extends StatelessWidget {
  const TowerDefenseGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Defense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState gameState;
  late TowerManager towerManager;
  late MapData currentMap;
  
  @override
  void initState() {
    super.initState();
    gameState = GameState();
    towerManager = TowerManager(gameState);
    currentMap = MapGenerator.generateRandomMap();
    
    // Listen for state changes
    gameState.notifier.addListener(() {
      if (mounted) setState(() {});
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game Board
          GameBoard(
            mapData: currentMap,
            towerManager: towerManager,
            onTowerPlaced: (tower) {
              setState(() {});
            },
          ),
          
          // HUD
          Positioned(
            top: 20,
            left: 20,
            child: HUD(gameState: gameState),
          ),
          
          // Tower Shop
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: TowerShop(
              gameState: gameState,
              towerManager: towerManager,
              mapData: currentMap,
              onTowerPlaced: () {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}