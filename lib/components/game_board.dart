import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../core/game_constants.dart';
import '../core/game_state.dart';
import '../systems/rendering_system.dart';

class GameBoard extends StatefulWidget {
  final GameState gameState;
  final List<(int, int)> pathPoints;
  final Function((int, int)?) onGridHover;
  final Function((int, int)?) onGridTap;
  
  const GameBoard({
    super.key,
    required this.gameState,
    required this.pathPoints,
    required this.onGridHover,
    required this.onGridTap,
  });
  
  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Update game state
        widget.gameState.updateDetailedChunks();
        
        return CustomPaint(
          size: ui.Size(
            GameConstants.metersToPixels(GameConstants.boardWidthMeters.toDouble()),
            GameConstants.metersToPixels(GameConstants.boardHeightMeters.toDouble()),
          ),
          painter: _GameBoardPainter(
            gameState: widget.gameState,
            pathPoints: widget.pathPoints,
          ),
        );
      },
    );
  }
}

class _GameBoardPainter extends CustomPainter {
  final GameState gameState;
  final List<(int, int)> pathPoints;
  
  _GameBoardPainter({
    required this.gameState,
    required this.pathPoints,
  });
  
  @override
  void paint(Canvas canvas, ui.Size size) {
    // Draw background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1E3A1F),
    );
    
    // Draw chunks with LOD optimization
    _drawChunks(canvas, size);
    
    // Draw path
    RenderingSystem.drawPath(canvas, pathPoints);
    
    // Draw towers
    for (var tower in gameState.towers) {
      RenderingSystem.drawTower(canvas, tower, false, true);
    }
    
    // Draw enemies
    for (var enemy in gameState.enemies) {
      RenderingSystem.drawEnemy(canvas, enemy);
    }
    
    // Draw projectiles
    for (var projectile in gameState.projectiles) {
      RenderingSystem.drawProjectile(canvas, projectile);
    }
    
    // Draw placement preview
    _drawPlacementPreview(canvas);
  }
  
  void _drawChunks(Canvas canvas, ui.Size size) {
    final viewport = ui.Rect.fromLTWH(0, 0, size.width, size.height);
    final visibleChunks = gameState.chunkManager.getVisibleChunks(viewport);
    
    for (var chunk in visibleChunks) {
      final bounds = chunk.bounds;
      if (!bounds.overlaps(viewport)) continue;
      
      final isDetailed = gameState.shouldRenderDetailedChunk('${chunk.x},${chunk.y}');
      RenderingSystem.drawChunkBackground(canvas, bounds, isDetailed);
    }
  }
  
  void _drawPlacementPreview(Canvas canvas) {
    final placement = gameState.currentPlacement;
    if (placement?.gridPosition == null) return;
    
    final specs = GameConstants.towerSpecs[placement!.type]!;
    final position = placement.pixelPosition!;
    final isValid = placement.isValid;
    
    // Draw range preview
    final rangePaint = Paint()
      ..color = specs.color.withOpacity(isValid ? 0.15 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, specs.rangePixels, rangePaint);
    
    // Draw tower preview
    final previewColor = isValid ? specs.color : Colors.grey;
    final towerPaint = Paint()..color = previewColor;
    canvas.drawCircle(position, GameConstants.metersToPixels(1.2), towerPaint);
    
    // Draw base
    final basePaint = Paint()..color = Colors.grey[800]!;
    canvas.drawCircle(position, GameConstants.metersToPixels(1.8), basePaint);
    
    // Draw validity indicator
    if (!isValid) {
      final crossPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      final crossSize = GameConstants.metersToPixels(1.2);
      canvas.drawLine(
        position - ui.Offset(crossSize, crossSize),
        position + ui.Offset(crossSize, crossSize),
        crossPaint,
      );
      canvas.drawLine(
        position - ui.Offset(crossSize, -crossSize),
        position + ui.Offset(crossSize, -crossSize),
        crossPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _GameBoardPainter oldDelegate) {
    return gameState.towers != oldDelegate.gameState.towers ||
           gameState.enemies != oldDelegate.gameState.enemies ||
           gameState.projectiles != oldDelegate.gameState.projectiles ||
           gameState.currentPlacement != oldDelegate.gameState.currentPlacement;
  }
}