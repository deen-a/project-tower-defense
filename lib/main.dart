import 'package:flutter/material.dart';
import 'dart:math';
import 'core/game_constants.dart';
import 'core/chunk_manager.dart';

// ============================
// TOWER MODEL
// ============================
class Tower {
  final (int, int) gridPosition;
  final String type;
  
  Tower({
    required this.gridPosition,
    required this.type,
  });
  
  Offset get pixelPosition {
    return GameConstants.gridToPixel(gridPosition.$1, gridPosition.$2);
  }
}

// ============================
// MAIN GAME
// ============================
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
  List<Tower> towers = [];
  int coins = 2000000;
  String? selectedTowerType;
  Offset? hoverPixelPosition;
  (int, int)? hoverGridPosition;
  GlobalKey gameBoardKey = GlobalKey();
  
  // Chunk system
  final ChunkManager chunkManager = ChunkManager();
  bool showDetailedGrid = false;
  
  // Board dimensions in pixels
  final double boardWidthPixels = GameConstants.metersToPixels(GameConstants.boardWidthMeters.toDouble());
  final double boardHeightPixels = GameConstants.metersToPixels(GameConstants.boardHeightMeters.toDouble());
  
  // Path definition (in grid coordinates - meters)
  final List<(int, int)> pathPoints = [
    (0, 50),   // Start at left middle
    (30, 50),
    (30, 20),
    (80, 20),
    (80, 70),
    (120, 70),
    (120, 30),
    (150, 30), // End at right
  ];
  
  @override
  void initState() {
    super.initState();
    // Initialize all chunks
    final chunksX = (boardWidthPixels / ChunkManager.chunkSize).ceil();
    final chunksY = (boardHeightPixels / ChunkManager.chunkSize).ceil();
    
    for (int x = 0; x < chunksX; x++) {
      for (int y = 0; y < chunksY; y++) {
        chunkManager.chunks['$x,$y'] = Chunk(x, y);
      }
    }
    _updateChunks();
  }
  
  void _updateChunks() {
    chunkManager.updateChunkActivity(towers, pathPoints);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tower Defense - Optimized'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive scaling
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight - 180; // HUD + Shop height
          
          final scaleX = availableWidth / boardWidthPixels;
          final scaleY = availableHeight / boardHeightPixels;
          final scale = min(scaleX, scaleY).clamp(0.5, 2.0);
          
          final scaledBoardWidth = boardWidthPixels * scale;
          final scaledBoardHeight = boardHeightPixels * scale;
          
          return Column(
            children: [
              // HUD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coins: $coins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Scale: ${scale.toStringAsFixed(2)}x',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          selectedTowerType != null 
                              ? 'Placing: ${GameConstants.towerSpecs[selectedTowerType]!.name}'
                              : 'Select a tower',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (hoverGridPosition != null)
                          Text(
                            'Grid: (${hoverGridPosition!.$1}m, ${hoverGridPosition!.$2}m)',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Chunks: ${chunkManager.activeChunks.length}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Row(
                              children: [
                                Switch(
                                  value: showDetailedGrid,
                                  onChanged: (value) {
                                    setState(() => showDetailedGrid = value);
                                  },
                                  activeColor: Colors.blue,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text(
                                  'Grid',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => coins += 100),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('+100 Coins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Game Board
              Expanded(
                child: Center(
                  child: Container(
                    key: gameBoardKey,
                    width: scaledBoardWidth,
                    height: scaledBoardHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade600),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: MouseRegion(
                      onHover: (event) {
                        if (selectedTowerType == null) return;
                        
                        final box = gameBoardKey.currentContext?.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        
                        // Get local position within the container
                        final localPos = box.globalToLocal(event.position);
                        
                        // Ensure position is within container bounds
                        if (localPos.dx < 0 || localPos.dy < 0 || 
                            localPos.dx > scaledBoardWidth || localPos.dy > scaledBoardHeight) {
                          setState(() {
                            hoverPixelPosition = null;
                            hoverGridPosition = null;
                          });
                          return;
                        }
                        
                        // Convert to unscaled game coordinates
                        final unscaledX = localPos.dx / scale;
                        final unscaledY = localPos.dy / scale;
                        
                        // Snap to grid (1 meter increments)
                        final gridX = (unscaledX / GameConstants.pixelsPerMeter).floor();
                        final gridY = (unscaledY / GameConstants.pixelsPerMeter).floor();
                        
                        // Clamp to board boundaries
                        final clampedX = gridX.clamp(0, GameConstants.boardWidthMeters - 1);
                        final clampedY = gridY.clamp(0, GameConstants.boardHeightMeters - 1);
                        
                        // Convert back to scaled pixel position for rendering
                        final pixelX = clampedX * GameConstants.pixelsPerMeter * scale;
                        final pixelY = clampedY * GameConstants.pixelsPerMeter * scale;
                        
                        setState(() {
                          hoverGridPosition = (clampedX, clampedY);
                          hoverPixelPosition = Offset(pixelX, pixelY);
                        });
                      },
                      onExit: (_) {
                        if (selectedTowerType != null) {
                          setState(() {
                            hoverPixelPosition = null;
                            hoverGridPosition = null;
                          });
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          if (selectedTowerType == null || hoverGridPosition == null) return;
                          
                          final (gridX, gridY) = hoverGridPosition!;
                          final towerPos = GameConstants.gridToPixel(gridX, gridY);
                          
                          if (_isValidPosition(towerPos, selectedTowerType!)) {
                            setState(() {
                              towers.add(Tower(
                                gridPosition: (gridX, gridY),
                                type: selectedTowerType!,
                              ));
                              coins -= GameConstants.towerSpecs[selectedTowerType!]!.cost;
                              _resetPlacement();
                              _updateChunks();
                            });
                          }
                        },
                        child: Transform.scale(
                          scale: scale,
                          child: CustomPaint(
                            size: Size(boardWidthPixels, boardHeightPixels),
                            painter: GameBoardPainter(
                              towers: towers,
                              pathPoints: pathPoints,
                              hoverPosition: hoverPixelPosition != null 
                                  ? Offset(
                                      hoverPixelPosition!.dx / scale,
                                      hoverPixelPosition!.dy / scale,
                                    )
                                  : null,
                              hoverGridPosition: hoverGridPosition,
                              selectedTowerType: selectedTowerType,
                              isValidPosition: (pos, type) => _isValidPosition(pos, type),
                              chunkManager: chunkManager,
                              showDetailedGrid: showDetailedGrid,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Tower Shop
              Container(
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
                        letterSpacing: 1,
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
              ),
            ],
          );
        },
      ),
    );
  }
  
  bool _isValidPosition(Offset pixelPosition, String towerType) {
    final specs = GameConstants.towerSpecs[towerType]!;
    final marginPixels = specs.placementMarginPixels;
    
    // 1. Check distance to path dengan margin 3 meter
    final totalPathWidth = GameConstants.pathWidthMeters + GameConstants.pathMarginMeters;
    
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = GameConstants.gridToPixel(pathPoints[i].$1, pathPoints[i].$2);
      final end = GameConstants.gridToPixel(pathPoints[i + 1].$1, pathPoints[i + 1].$2);
      
      if (_isPointNearLine(pixelPosition, start, end, totalPathWidth / 2)) {
        return false;
      }
    }
    
    // 2. Check distance to existing towers
    for (var tower in towers) {
      final towerPos = tower.pixelPosition;
      final distance = (towerPos - pixelPosition).distance;
      final requiredDistance = marginPixels + 
          GameConstants.towerSpecs[tower.type]!.placementMarginPixels;
      
      if (distance < requiredDistance) {
        return false;
      }
    }
    
    // 3. Check boundaries
    final (gridX, gridY) = GameConstants.pixelToGrid(pixelPosition);
    
    if (gridX < 0 || gridX >= GameConstants.boardWidthMeters ||
        gridY < 0 || gridY >= GameConstants.boardHeightMeters) {
      return false;
    }
    
    return true;
  }
  
  bool _isPointNearLine(Offset point, Offset lineStart, Offset lineEnd, double threshold) {
    final lineLength = (lineEnd - lineStart).distance;
    if (lineLength == 0) return (point - lineStart).distance <= threshold;
    
    // Project point onto line segment
    final lineVec = lineEnd - lineStart;
    final pointVec = point - lineStart;
    final t = (pointVec.dx * lineVec.dx + pointVec.dy * lineVec.dy) / (lineLength * lineLength);
    
    if (t < 0) return (point - lineStart).distance <= threshold;
    if (t > 1) return (point - lineEnd).distance <= threshold;
    
    // Closest point on line segment
    final closestPoint = lineStart + Offset(lineVec.dx * t, lineVec.dy * t);
    return (point - closestPoint).distance <= threshold;
  }
  
  void _resetPlacement() {
    setState(() {
      selectedTowerType = null;
      hoverPixelPosition = null;
      hoverGridPosition = null;
    });
  }
  
  Widget _buildTowerButton(String type) {
    final specs = GameConstants.towerSpecs[type]!;
    final isSelected = selectedTowerType == type;
    final canAfford = coins >= specs.cost;
    
    return GestureDetector(
      onTap: canAfford ? () {
        setState(() {
          selectedTowerType = type;
        });
      } : null,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: specs.color.withOpacity(canAfford ? 0.9 : 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: specs.color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              specs.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              specs.name.split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${specs.cost}',
              style: TextStyle(
                color: canAfford ? Colors.yellow : Colors.red[300],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${specs.range}m',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _resetPlacement,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selectedTowerType == null ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 2),
            const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'ESC',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================
// GAME BOARD PAINTER
// ============================
class GameBoardPainter extends CustomPainter {
  final List<Tower> towers;
  final List<(int, int)> pathPoints;
  final Offset? hoverPosition;
  final (int, int)? hoverGridPosition;
  final String? selectedTowerType;
  final bool Function(Offset, String) isValidPosition;
  final ChunkManager chunkManager;
  final bool showDetailedGrid;
  
  GameBoardPainter({
    required this.towers,
    required this.pathPoints,
    this.hoverPosition,
    this.hoverGridPosition,
    this.selectedTowerType,
    required this.isValidPosition,
    required this.chunkManager,
    required this.showDetailedGrid,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    _drawBackground(canvas, size);
    
    // Draw chunks (optimized rendering)
    _drawChunks(canvas, size);
    
    // Draw path
    _drawPath(canvas);
    
    // Draw placement overlay (only in active chunks)
    if (selectedTowerType != null) {
      _drawPlacementOverlay(canvas, size);
    }
    
    // Draw existing towers
    _drawTowers(canvas);
    
    // Draw hover preview
    if (hoverPosition != null && selectedTowerType != null) {
      _drawHoverPreview(canvas);
    }
  }
  
  void _drawBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFF1E3A1F);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  }
  
  void _drawChunks(Canvas canvas, Size size) {
    final viewport = Rect.fromLTWH(0, 0, size.width, size.height);
    final visibleChunks = chunkManager.getVisibleChunks(viewport);
    
    for (var chunk in visibleChunks) {
      final bounds = chunk.bounds;
      
      if (!bounds.overlaps(viewport)) continue;
      
      final isActive = chunkManager.activeChunks.contains('${chunk.x},${chunk.y}');
      
      if (isActive || showDetailedGrid) {
        // Draw detailed grid for active chunks
        _drawDetailedGrid(canvas, bounds);
      } else {
        // Draw simple chunk for inactive areas (performance optimized)
        _drawSimpleChunk(canvas, bounds);
      }
    }
  }
  
  void _drawDetailedGrid(Canvas canvas, Rect bounds) {
    // Draw chunk background
    final chunkBgPaint = Paint()..color = const Color(0xFF2D5A27);
    canvas.drawRect(bounds, chunkBgPaint);
    
    // Draw fine grid (1 meter)
    final fineGridPaint = Paint()
      ..color = const Color(0xFF3A6B33).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    final startX = bounds.left;
    final endX = bounds.right;
    final startY = bounds.top;
    final endY = bounds.bottom;
    
    // Draw vertical lines
    for (double x = startX; x <= endX; x += GameConstants.pixelsPerMeter) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), fineGridPaint);
    }
    
    // Draw horizontal lines
    for (double y = startY; y <= endY; y += GameConstants.pixelsPerMeter) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), fineGridPaint);
    }
    
    // Draw chunk border
    final chunkBorderPaint = Paint()
      ..color = const Color(0xFF4A7A43).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawRect(bounds, chunkBorderPaint);
  }
  
  void _drawSimpleChunk(Canvas canvas, Rect bounds) {
    // Simple dark background for inactive chunks
    final chunkPaint = Paint()..color = const Color(0xFF1E3A1F);
    canvas.drawRect(bounds, chunkPaint);
    
    // Very subtle pattern for distant chunks
    final patternPaint = Paint()
      ..color = const Color(0xFF2D5A27).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    // Draw only major grid lines (every 10 meters = 50px)
    for (double x = bounds.left; x <= bounds.right; x += GameConstants.pixelsPerMeter * 10) {
      canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), patternPaint);
    }
    for (double y = bounds.top; y <= bounds.bottom; y += GameConstants.pixelsPerMeter * 10) {
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), patternPaint);
    }
  }
  
  void _drawPath(Canvas canvas) {
    final pathWidthPixels = GameConstants.metersToPixels(GameConstants.pathWidthMeters);
    
    // Draw path segments
    final pathPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidthPixels;
    
    final pathBorderPaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = GameConstants.gridToPixel(pathPoints[i].$1, pathPoints[i].$2);
      final end = GameConstants.gridToPixel(pathPoints[i + 1].$1, pathPoints[i + 1].$2);
      
      canvas.drawLine(start, end, pathPaint);
      canvas.drawLine(start, end, pathBorderPaint);
    }
    
    // Draw start and end markers
    final startPoint = GameConstants.gridToPixel(pathPoints.first.$1, pathPoints.first.$2);
    final endPoint = GameConstants.gridToPixel(pathPoints.last.$1, pathPoints.last.$2);
    
    final startPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final endPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(startPoint, 8, startPaint);
    canvas.drawCircle(endPoint, 8, endPaint);
    
    // Draw labels
    _drawText(canvas, 'START', startPoint + const Offset(12, -12), Colors.red, 10);
    _drawText(canvas, 'END', endPoint + const Offset(12, -12), Colors.blue, 10);
  }
  
  void _drawPlacementOverlay(Canvas canvas, Size size) {
    if (selectedTowerType == null) return;
    
    final viewport = Rect.fromLTWH(0, 0, size.width, size.height);
    final visibleChunks = chunkManager.getVisibleChunks(viewport);
    
    for (var chunk in visibleChunks) {
      // Only draw overlay in active chunks (performance optimization)
      if (!chunkManager.activeChunks.contains('${chunk.x},${chunk.y}')) {
        continue;
      }
      
      final bounds = chunk.bounds;
      
      // Calculate grid range for this chunk
      final startGridX = (bounds.left / GameConstants.pixelsPerMeter).floor();
      final startGridY = (bounds.top / GameConstants.pixelsPerMeter).floor();
      final endGridX = min((bounds.right / GameConstants.pixelsPerMeter).ceil(), GameConstants.boardWidthMeters);
      final endGridY = min((bounds.bottom / GameConstants.pixelsPerMeter).ceil(), GameConstants.boardHeightMeters);
      
      // Draw placement overlay for each grid cell in chunk
      for (int x = startGridX; x < endGridX; x++) {
        for (int y = startGridY; y < endGridY; y++) {
          final cellCenter = GameConstants.gridToPixel(x, y);
          final isValid = isValidPosition(cellCenter, selectedTowerType!);
          
          final cellRect = Rect.fromCenter(
            center: cellCenter,
            width: GameConstants.pixelsPerMeter,
            height: GameConstants.pixelsPerMeter,
          );
          
          final overlayPaint = Paint()
            ..color = isValid ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.03)
            ..style = PaintingStyle.fill;
          
          canvas.drawRect(cellRect, overlayPaint);
          
          if (isValid) {
            final borderPaint = Paint()
              ..color = Colors.green.withOpacity(0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.3;
            canvas.drawRect(cellRect, borderPaint);
          }
        }
      }
    }
  }
  
  void _drawTowers(Canvas canvas) {
    for (var tower in towers) {
      final specs = GameConstants.towerSpecs[tower.type]!;
      final position = tower.pixelPosition;
      
      // Draw range indicator (subtle)
      final rangePaint = Paint()
        ..color = specs.color.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, specs.rangePixels, rangePaint);
      
      // Draw secondary range for flamethrower
      if (specs.secondaryRangePixels != null) {
        final secondaryPaint = Paint()
          ..color = specs.color.withOpacity(0.04)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(position, specs.secondaryRangePixels!, secondaryPaint);
      }
      
      // Draw tower base
      final basePaint = Paint()
        ..color = Colors.grey[900]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, GameConstants.metersToPixels(1.8), basePaint);
      
      // Draw tower
      final towerPaint = Paint()..color = specs.color;
      canvas.drawCircle(position, GameConstants.metersToPixels(1.2), towerPaint);
      
      // Draw tower type indicator
      _drawText(
        canvas, 
        tower.type[0].toUpperCase(), 
        position, 
        Colors.white, 
        10
      );
    }
  }
  
  void _drawHoverPreview(Canvas canvas) {
    if (hoverPosition == null || selectedTowerType == null) return;
    
    final specs = GameConstants.towerSpecs[selectedTowerType]!;
    final isValid = isValidPosition(hoverPosition!, selectedTowerType!);
    
    // Draw range preview
    final rangePaint = Paint()
      ..color = specs.color.withOpacity(isValid ? 0.15 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hoverPosition!, specs.rangePixels, rangePaint);
    
    if (specs.secondaryRangePixels != null) {
      final secondaryPaint = Paint()
        ..color = specs.color.withOpacity(isValid ? 0.08 : 0.04)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(hoverPosition!, specs.secondaryRangePixels!, secondaryPaint);
    }
    
    // Draw tower preview
    final previewColor = isValid ? specs.color : Colors.grey;
    final towerPaint = Paint()..color = previewColor;
    canvas.drawCircle(hoverPosition!, GameConstants.metersToPixels(1.2), towerPaint);
    
    final basePaint = Paint()..color = Colors.grey[800]!;
    canvas.drawCircle(hoverPosition!, GameConstants.metersToPixels(1.8), basePaint);
    
    // Draw validity indicator
    if (!isValid) {
      final crossPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      final crossSize = GameConstants.metersToPixels(1.2);
      canvas.drawLine(
        hoverPosition! - Offset(crossSize, crossSize),
        hoverPosition! + Offset(crossSize, crossSize),
        crossPaint,
      );
      canvas.drawLine(
        hoverPosition! - Offset(crossSize, -crossSize),
        hoverPosition! + Offset(crossSize, -crossSize),
        crossPaint,
      );
    }
    
    // Draw coordinates
    if (hoverGridPosition != null) {
      _drawText(
        canvas,
        '(${hoverGridPosition!.$1}, ${hoverGridPosition!.$2})',
        hoverPosition! + const Offset(10, 10),
        Colors.white,
        9
      );
    }
  }
  
  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(
          color: Colors.black,
          blurRadius: 2,
          offset: Offset(1, 1),
        ),
      ],
    );
    
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(canvas, position);
  }
  
  @override
  bool shouldRepaint(covariant GameBoardPainter oldDelegate) {
    return towers != oldDelegate.towers ||
           hoverPosition != oldDelegate.hoverPosition ||
           hoverGridPosition != oldDelegate.hoverGridPosition ||
           selectedTowerType != oldDelegate.selectedTowerType ||
           showDetailedGrid != oldDelegate.showDetailedGrid;
  }
}