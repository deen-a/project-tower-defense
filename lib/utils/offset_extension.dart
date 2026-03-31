import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

extension OffsetMath on ui.Offset {
  /// Returns a normalized version of the offset (length = 1)
  ui.Offset get normalized {
    final length = this.distance;
    if (length == 0) return Offset.zero;
    return Offset(dx / length, dy / length);
  }
  
  /// Returns the angle of this offset in radians
  double get angle => atan2(dy, dx);
  
  /// Rotates this offset by given angle in radians
  ui.Offset rotate(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      dx * cosA - dy * sinA,
      dx * sinA + dy * cosA,
    );
  }
  
  /// Returns distance between two offsets
  static double distanceBetween(ui.Offset a, ui.Offset b) {
    return (a - b).distance;
  }
  
  /// Linearly interpolates between two offsets
  static ui.Offset lerp(ui.Offset a, ui.Offset b, double t) {
    return ui.Offset(
      a.dx + (b.dx - a.dx) * t,
      a.dy + (b.dy - a.dy) * t,
    );
  }

  /// Add two offsets
  ui.Offset operator +(ui.Offset other) => ui.Offset(dx + other.dx, dy + other.dy);
  
  /// Subtract two offsets
  ui.Offset operator -(ui.Offset other) => ui.Offset(dx - other.dx, dy - other.dy);
}