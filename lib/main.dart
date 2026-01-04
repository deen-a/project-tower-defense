import 'package:flutter/material.dart';
import 'core/game_constants.dart';
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

class _GameScreenState extends State<GameScreen> {
  List<Tower> towers = [];
  int coins = 2000000;
  String? selectedTowerType;
  Offset? hoverPixelPosition;
  (int, int)? hoverGridPosition;
  GlobalKey gameBoardKey = GlobalKey();
  
  // Board dimensions in pixels
  final double boardWidthPixels = GameConstants.metersToPixels(GameConstants.boardWidthMeters.toDouble());
  final double boardHeightPixels = GameConstants.metersToPixels(GameConstants.boardHeightMeters.toDouble());
  
  // Simple path definition (in grid coordinates - meters)
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tower Defense - Metric System'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive scaling
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight - 200;
          
          final scaleX = availableWidth / boardWidthPixels;
          final scaleY = availableHeight / boardHeightPixels;
          final scale = scaleX < scaleY ? scaleX : scaleY;
          
          final scaledBoardWidth = boardWidthPixels * scale;
          final scaledBoardHeight = boardHeightPixels * scale;
          
          return Column(
            children: [
              // HUD
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Scale: ${scale.toStringAsFixed(2)}x',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedTowerType != null 
                              ? 'Placing: ${GameConstants.towerSpecs[selectedTowerType]!.name}'
                              : 'Click a tower to place',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        if (hoverGridPosition != null)
                          Text(
                            'Position: (${hoverGridPosition!.$1}m, ${hoverGridPosition!.$2}m)',
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => coins += 100),
                      child: const Text('Add Coins'),
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
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: MouseRegion(
                      onHover: (event) {
                        if (selectedTowerType == null) return;
                        
                        // Get local position within the scaled container
                        final box = gameBoardKey.currentContext?.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        
                        final localPosition = box.globalToLocal(event.position);
                        
                        // Adjust for scaling
                        final unscaledX = localPosition.dx / scale;
                        final unscaledY = localPosition.dy / scale;
                        
                        // Snap to grid (1 meter increments)
                        final gridX = (unscaledX / GameConstants.pixelsPerMeter).floor();
                        final gridY = (unscaledY / GameConstants.pixelsPerMeter).floor();
                        
                        // Convert back to scaled pixel position
                        final pixelX = gridX * GameConstants.pixelsPerMeter * scale;
                        final pixelY = gridY * GameConstants.pixelsPerMeter * scale;
                        
                        // Update hover position (scaled for rendering)
                        final scaledHoverPosition = Offset(pixelX, pixelY);
                        
                        setState(() {
                          hoverGridPosition = (gridX, gridY);
                          hoverPixelPosition = scaledHoverPosition;
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
                          
                          // Convert grid to unscaled pixel position
                          final towerPixelPosition = GameConstants.gridToPixel(gridX, gridY);
                          
                          if (_isValidPosition(towerPixelPosition, selectedTowerType!)) {
                            setState(() {
                              towers.add(Tower(
                                gridPosition: (gridX, gridY),
                                type: selectedTowerType!,
                              ));
                              coins -= GameConstants.towerSpecs[selectedTowerType!]!.cost;
                              _resetPlacement();
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
                height: 120,
                color: Colors.grey[900],
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      'TOWER SHOP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
    
    // 1. Check if position is on path
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = GameConstants.gridToPixel(pathPoints[i].$1, pathPoints[i].$2);
      final end = GameConstants.gridToPixel(pathPoints[i + 1].$1, pathPoints[i + 1].$2);
      
      // Simple path width (8 meters)
      final pathWidth = GameConstants.metersToPixels(8);
      if (_isPointNearLine(pixelPosition, start, end, pathWidth / 2)) {
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
        width: 80,
        decoration: BoxDecoration(
          color: specs.color.withOpacity(canAfford ? 0.9 : 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              specs.icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              specs.name.split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${specs.cost}',
              style: TextStyle(
                color: canAfford ? Colors.yellow : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${specs.range}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
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
        width: 80,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedTowerType == null ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'ESC',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class GameBoardPainter extends CustomPainter {
  final List<Tower> towers;
  final List<(int, int)> pathPoints;
  final Offset? hoverPosition;
  final (int, int)? hoverGridPosition;
  final String? selectedTowerType;
  final bool Function(Offset, String) isValidPosition;
  
  GameBoardPainter({
    required this.towers,
    required this.pathPoints,
    this.hoverPosition,
    this.hoverGridPosition,
    this.selectedTowerType,
    required this.isValidPosition,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    _drawBackground(canvas, size);
    
    // Draw grid
    _drawGrid(canvas, size);
    
    // Draw path
    _drawPath(canvas);
    
    // Draw placement overlay
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
    final backgroundPaint = Paint()..color = const Color(0xFF2D5A27);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  }
  
  void _drawGrid(Canvas canvas, Size size) {
    // Fine grid (1 meter)
    final fineGridPaint = Paint()
      ..color = const Color(0xFF3A6B33).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    for (double x = 0; x <= size.width; x += GameConstants.pixelsPerMeter) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fineGridPaint);
    }
    for (double y = 0; y <= size.height; y += GameConstants.pixelsPerMeter) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fineGridPaint);
    }
    
    // Major grid (10 meters)
    final majorGridPaint = Paint()
      ..color = const Color(0xFF4A7A43).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (double x = 0; x <= size.width; x += GameConstants.pixelsPerMeter * 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorGridPaint);
    }
    for (double y = 0; y <= size.height; y += GameConstants.pixelsPerMeter * 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorGridPaint);
    }
  }
  
  void _drawPath(Canvas canvas) {
    final pathPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.metersToPixels(8);
    
    final pathBorderPaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw path segments
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
    
    canvas.drawCircle(startPoint, 10, startPaint);
    canvas.drawCircle(endPoint, 10, endPaint);
    
    // Draw start/end labels
    _drawText(canvas, 'START', startPoint + const Offset(15, -15), Colors.red);
    _drawText(canvas, 'END', endPoint + const Offset(15, -15), Colors.blue);
  }
  
  void _drawPlacementOverlay(Canvas canvas, Size size) {
    if (selectedTowerType == null) return;
    
    final specs = GameConstants.towerSpecs[selectedTowerType]!;
    
    // Check each grid cell
    for (int x = 0; x < GameConstants.boardWidthMeters; x++) {
      for (int y = 0; y < GameConstants.boardHeightMeters; y++) {
        final cellCenter = GameConstants.gridToPixel(x, y);
        final isValid = isValidPosition(cellCenter, selectedTowerType!);
        
        final cellRect = Rect.fromCenter(
          center: cellCenter,
          width: GameConstants.pixelsPerMeter,
          height: GameConstants.pixelsPerMeter,
        );
        
        final overlayPaint = Paint()
          ..color = isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.05)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(cellRect, overlayPaint);
        
        // Draw border for valid cells
        if (isValid) {
          final borderPaint = Paint()
            ..color = Colors.green.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRect(cellRect, borderPaint);
        }
      }
    }
  }
  
  void _drawTowers(Canvas canvas) {
    for (var tower in towers) {
      final specs = GameConstants.towerSpecs[tower.type]!;
      final position = tower.pixelPosition;
      
      // Draw range indicator
      final rangePaint = Paint()
        ..color = specs.color.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, specs.rangePixels, rangePaint);
      
      if (specs.secondaryRangePixels != null) {
        final secondaryPaint = Paint()
          ..color = specs.color.withOpacity(0.05)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(position, specs.secondaryRangePixels!, secondaryPaint);
      }
      
      // Draw tower base
      final basePaint = Paint()
        ..color = Colors.grey[800]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, GameConstants.metersToPixels(2), basePaint);
      
      // Draw tower
      final towerPaint = Paint()..color = specs.color;
      canvas.drawCircle(position, GameConstants.metersToPixels(1.2), towerPaint);
      
      // Draw tower type indicator
      _drawText(canvas, tower.type[0].toUpperCase(), position, Colors.white, fontSize: 12);
    }
  }
  
  void _drawHoverPreview(Canvas canvas) {
    if (hoverPosition == null || selectedTowerType == null) return;
    
    final specs = GameConstants.towerSpecs[selectedTowerType]!;
    final isValid = isValidPosition(hoverPosition!, selectedTowerType!);
    
    // Draw range preview
    final rangePaint = Paint()
      ..color = specs.color.withOpacity(isValid ? 0.2 : 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hoverPosition!, specs.rangePixels, rangePaint);
    
    if (specs.secondaryRangePixels != null) {
      final secondaryPaint = Paint()
        ..color = specs.color.withOpacity(isValid ? 0.1 : 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(hoverPosition!, specs.secondaryRangePixels!, secondaryPaint);
    }
    
    // Draw tower preview
    final previewColor = isValid ? specs.color : Colors.grey;
    final towerPaint = Paint()..color = previewColor;
    canvas.drawCircle(hoverPosition!, GameConstants.metersToPixels(1.2), towerPaint);
    
    final basePaint = Paint()..color = Colors.grey[800]!;
    canvas.drawCircle(hoverPosition!, GameConstants.metersToPixels(2), basePaint);
    
    // Draw validity indicator
    if (!isValid) {
      final crossPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      final crossSize = GameConstants.metersToPixels(1.5);
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
        hoverPosition! + const Offset(15, 15),
        Colors.white,
        fontSize: 11,
      );
    }
  }
  
  void _drawText(Canvas canvas, String text, Offset position, Color color, {double fontSize = 12}) {
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
           selectedTowerType != oldDelegate.selectedTowerType;
  }
}