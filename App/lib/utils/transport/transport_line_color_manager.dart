import 'package:flutter/material.dart';

class TransportLineColorManager {
  static final Map<int, Color> _colors = {};

  // =========================
  // BASE COLOR
  // =========================
  static Color getBaseColor(int id) {
    if (_colors.containsKey(id)) return _colors[id]!;

    final color = _generateVibrantColor(id);

    _colors[id] = color;
    return color;
  }

  // =========================
  // RETURN COLOR
  // =========================
  static Color getReturnColor(int id) {
    return getBaseColor(id).withValues(alpha: 0.5);
  }

  // =========================
  // COLOR GENERATION
  // =========================
  static Color _generateVibrantColor(int id) {
    final normalized = id.abs();
    final hue = (normalized * 137.508) % 360;
    final saturation = 0.76 + ((normalized % 5) * 0.04);
    final value = 0.74 + ((normalized % 4) * 0.05);

    return HSVColor.fromAHSV(1, hue, saturation, value).toColor();
  }
}
