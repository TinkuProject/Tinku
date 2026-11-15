import 'package:flutter/material.dart';

double contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

Color accessibleOnLight(
  Color foreground,
  Color background, {
  double minimumRatio = 4.5,
}) {
  if (contrastRatio(foreground, background) >= minimumRatio) {
    return foreground;
  }

  for (var step = 1; step <= 20; step++) {
    final candidate = Color.lerp(foreground, Colors.black, step / 20)!;
    if (contrastRatio(candidate, background) >= minimumRatio) {
      return candidate;
    }
  }

  return Colors.black;
}
