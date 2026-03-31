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

class _GameBoardState extends State<GameBoard> {
  // Cache untuk performance
  late ui.Size _boardSize;
  List<ui.Offset> _pathPixelPoints = [];
  
  @override
  void initState() {
    super.initState();
    _boardSize = ui.Size(
      GameConstants.metersToPixels(GameConstants.boardWidthMeters.toDouble()),
      GameConstants.metersToPixels(GameConstants.boardHeightMeters.toDouble()),
    );
    _pathPixelPoints = _convertPathToPixels();
  }
  
  List<ui.Offset> _convertPathToPixels() {
    return widget.pathPoints.map((point) {
      return GameConstants.gridToPixel(point.$1, point.$2);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.gameState.updateNotifier,
      builder: (context, value, child) {
        return CustomPaint(
          size: _boardSize,
          painter: _GameBoardPainter(
            gameState: widget.gameState,
            pathPoints: widget.pathPoints,
            pathPixelPoints: _pathPixelPoints,
            frameCount: value,
          ),
        );
      },
    );
  }
}

class _GameBoardPainter extends CustomPainter {
  final GameState gameState;
  final List<(int, int)> pathPoints;
  final List<ui.Offset> pathPixelPoints;
  final int frameCount;
  
  // Cache untuk performance
  final Paint _backgroundPaint = Paint()..color = const Color(0xFF1E3A1F);
  final Paint _baseBackgroundPaint = Paint()..color = Colors.blue.withOpacity(0.3);
  final Paint _baseHealthBgPaint = Paint()..color = Colors.red[800]!;
  final Paint _baseHealthPaint = Paint()..color = Colors.green;
  
  _GameBoardPainter({
    required this.gameState,
    required this.pathPoints,
    required this.pathPixelPoints,
    required this.frameCount,
  });
  
  @override
  void paint(Canvas canvas, ui.Size size) {
    // Draw background
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);
    
    // Draw chunks with LOD optimization - HANYA jika perlu
    _drawChunks(canvas, size);
    
    // Draw path
    _drawPath(canvas);
    
    // Draw base/finish line
    _drawBase(canvas);
    
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
    
    // Draw FPS (debug)
    _drawFPS(canvas);
  }
  
  void _drawChunks(Canvas canvas, ui.Size size) {
    final viewport = ui.Rect.fromLTWH(0, 0, size.width, size.height);
    final visibleChunks = gameState.chunkManager.getVisibleChunks(viewport);
    
    for (var chunk in visibleChunks) {
      final bounds = chunk.bounds;
      if (!bounds.overlaps(viewport)) continue;
      
      final isDetailed = gameState.shouldRenderDetailedChunk('${chunk.x},${chunk.y}');
      if (isDetailed) {
        RenderingSystem.drawChunkBackground(canvas, bounds, true);
      } else {
        // Simple chunk - sangat minimal
        final simplePaint = Paint()..color = const Color(0xFF1E3A1F);
        canvas.drawRect(bounds, simplePaint);
      }
    }
  }
  
  void _drawPath(Canvas canvas) {
    final pathWidthPixels = GameConstants.pathWidthPixels;
    
    // Draw path segments
    final pathPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidthPixels
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < pathPixelPoints.length - 1; i++) {
      canvas.drawLine(pathPixelPoints[i], pathPixelPoints[i + 1], pathPaint);
    }
    
    // Draw start/end markers
    final startPoint = pathPixelPoints.first;
    final endPoint = pathPixelPoints.last;
    
    canvas.drawCircle(startPoint, 8, Paint()..color = Colors.red);
    canvas.drawCircle(endPoint, 8, Paint()..color = Colors.blue);
  }
  
  void _drawBase(Canvas canvas) {
    final endPoint = pathPixelPoints.last;
    
    // Base background
    final baseRect = ui.Rect.fromCircle(
      center: endPoint,
      radius: 20,
    );
    
    canvas.drawRect(baseRect, _baseBackgroundPaint);
    
    // Base health bar
    final healthPercent = gameState.baseHealth / gameState.maxBaseHealth;
    final healthBarWidth = 60;
    final healthBarHeight = 8;
    final healthBarY = endPoint.dy - 30;
    
    // Background
    canvas.drawRect(
      ui.Rect.fromCenter(
        center: ui.Offset(endPoint.dx, healthBarY),
        width: healthBarWidth.toDouble(),
        height: healthBarHeight.toDouble(),
      ),
      _baseHealthBgPaint,
    );
    
    // Current health
    canvas.drawRect(
      ui.Rect.fromCenter(
        center: ui.Offset(endPoint.dx - healthBarWidth * (1 - healthPercent) / 2, healthBarY),
        width: healthBarWidth * healthPercent,
        height: healthBarHeight.toDouble(),
      ),
      _baseHealthPaint,
    );
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
    final previewColor = isValid ? specs.color : Colors.grey[500]!;
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
  
  void _drawFPS(Canvas canvas) {
    final textSpan = TextSpan(
      text: 'FPS: ${gameState.fps.toStringAsFixed(1)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(canvas, const ui.Offset(5, 5));
  }
  
  @override
  bool shouldRepaint(covariant _GameBoardPainter oldDelegate) {
    // Hanya repaint jika ada perubahan signifikan
    return gameState.towers.length != oldDelegate.gameState.towers.length ||
           gameState.enemies.length != oldDelegate.gameState.enemies.length ||
           gameState.projectiles.length != oldDelegate.gameState.projectiles.length ||
           gameState.currentPlacement != oldDelegate.gameState.currentPlacement ||
           gameState.baseHealth != oldDelegate.gameState.baseHealth ||
           frameCount != oldDelegate.frameCount;
  }
}