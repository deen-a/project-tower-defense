import 'dart:math';
import 'package:flutter/material.dart';

extension OffsetMath on Offset {
  /// Returns a normalized version of the offset (length = 1)
  Offset get normalized {
    final length = this.distance;
    if (length == 0) return Offset.zero;
    return Offset(dx / length, dy / length);
  }
  
  /// Returns the angle of this offset in radians
  double get angle => atan2(dy, dx);
  
  /// Rotates this offset by given angle in radians
  Offset rotate(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      dx * cosA - dy * sinA,
      dx * sinA + dy * cosA,
    );
  }
  
  /// Returns distance between two offsets
  static double distanceBetween(Offset a, Offset b) {
    return (a - b).distance;
  }
  
  /// Linearly interpolates between two offsets
  static Offset lerp(Offset a, Offset b, double t) {
    return Offset(
      a.dx + (b.dx - a.dx) * t,
      a.dy + (b.dy - a.dy) * t,
    );
  }
}