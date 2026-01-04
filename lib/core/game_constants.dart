import 'package:flutter/material.dart';

class GameConstants {
  // Grid System: 5px = 1 meter
  static const double pixelsPerMeter = 5.0;
  static const double meterPerPixel = 1.0 / pixelsPerMeter;
  
  // Game Board Size (in meters)
  static const int boardWidthMeters = 150;  // 150m = 750px
  static const int boardHeightMeters = 100; // 100m = 500px
  
  // Convert meters to pixels
  static double metersToPixels(double meters) => meters * pixelsPerMeter;
  static double pixelsToMeters(double pixels) => pixels * meterPerPixel;
  
  // Convert grid position (in meters) to pixel position
  static Offset gridToPixel(int gridX, int gridY) {
    return Offset(
      gridX * pixelsPerMeter + pixelsPerMeter / 2,
      gridY * pixelsPerMeter + pixelsPerMeter / 2,
    );
  }
  
  // Convert pixel position to grid position (in meters)
  static (int, int) pixelToGrid(Offset pixelPosition) {
    return (
      (pixelPosition.dx / pixelsPerMeter).floor(),
      (pixelPosition.dy / pixelsPerMeter).floor(),
    );
  }
  
  // Tower Specifications (in meters)
  static const Map<String, TowerSpecs> towerSpecs = {
    'basic': TowerSpecs(
      name: 'Basic Tower',
      cost: 75,
      damage: 15,
      fireRate: 1.0,
      range: 15.0,
      placementMargin: 2.0,
      color: Colors.blue,
      icon: Icons.tour,
    ),
    'burst': TowerSpecs(
      name: 'Rapid Tower',
      cost: 125,
      damage: 8,
      fireRate: 3.33,
      range: 15.0,
      placementMargin: 2.0,
      color: Colors.red,
      icon: Icons.burst_mode,
    ),
    'railgun': TowerSpecs(
      name: 'Sniper Tower',
      cost: 225,
      damage: 40,
      fireRate: 0.4,
      range: 32.0,
      placementMargin: 4.0,
      color: Colors.purple,
      icon: Icons.track_changes,
    ),
    'flamethrower': TowerSpecs(
      name: 'Flamethrower',
      cost: 150,
      damage: 5,
      fireRate: 10.0,
      range: 12.0,
      secondaryRange: 18.0,
      placementMargin: 3.0,
      color: Colors.orange,
      icon: Icons.local_fire_department,
    ),
  };
}

class TowerSpecs {
  final String name;
  final int cost;
  final int damage;
  final double fireRate;
  final double range;
  final double? secondaryRange;
  final double placementMargin;
  final Color color;
  final IconData icon;
  
  const TowerSpecs({
    required this.name,
    required this.cost,
    required this.damage,
    required this.fireRate,
    required this.range,
    this.secondaryRange,
    required this.placementMargin,
    required this.color,
    required this.icon,
  });
  
  double get rangePixels => GameConstants.metersToPixels(range);
  double get placementMarginPixels => GameConstants.metersToPixels(placementMargin);
  double? get secondaryRangePixels => secondaryRange != null 
      ? GameConstants.metersToPixels(secondaryRange!) 
      : null;
}