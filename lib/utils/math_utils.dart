import 'dart:math';

class MathUtils {
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
  
  static double clamp(double value, double min, double max) {
    return value < min ? min : value > max ? max : value;
  }
  
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }
  
  static double angleBetween(double x1, double y1, double x2, double y2) {
    return atan2(y2 - y1, x2 - x1);
  }
}