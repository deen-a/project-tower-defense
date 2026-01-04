import 'dart:math';
import 'package:flutter/material.dart';

extension OffsetExtension on Offset {
  Offset normalized() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }

  Offset operator /(double d) => Offset(dx / d, dy / d);
}
