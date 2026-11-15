import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TransportMapMarkerType { stop, start, end, arrow, chevron }

class TransportMapMarkerHelper {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> getIcon({
    required TransportMapMarkerType type,
    required Color color,
  }) async {
    final key = '${type.name}_${color.toARGB32()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final icon = await _drawIcon(type: type, color: color);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _drawIcon({
    required TransportMapMarkerType type,
    required Color color,
  }) async {
    final size = switch (type) {
      TransportMapMarkerType.stop => 28.0,
      TransportMapMarkerType.arrow => 34.0,
      TransportMapMarkerType.chevron => 38.0,
      _ => 42.0,
    };
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    if (type == TransportMapMarkerType.arrow ||
        type == TransportMapMarkerType.chevron) {
      _drawArrow(canvas, center, size, color, type);
    } else {
      _drawStop(canvas, center, size, color, type);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.ceil(), size.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  static void _drawStop(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    TransportMapMarkerType type,
  ) {
    final isTerminal = type != TransportMapMarkerType.stop;
    final radius = isTerminal ? size * 0.34 : size * 0.23;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isTerminal ? color : Colors.white
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isTerminal ? 3.0 : 3.2
        ..isAntiAlias = true,
    );

    if (!isTerminal) return;

    if (type == TransportMapMarkerType.start) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.directions_bus.codePoint),
          style: TextStyle(
            color: Colors.white,
            fontFamily: Icons.directions_bus.fontFamily,
            fontSize: size * 0.42,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    } else {
      canvas.drawCircle(
        center,
        size * 0.13,
        Paint()
          ..color = Colors.white
          ..isAntiAlias = true,
      );
    }
  }

  static void _drawArrow(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    TransportMapMarkerType type,
  ) {
    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 7
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..isAntiAlias = true;

    final path = type == TransportMapMarkerType.chevron
        ? (Path()
          ..moveTo(size * 0.26, size * 0.30)
          ..lineTo(size * 0.44, center.dy)
          ..lineTo(size * 0.26, size * 0.70)
          ..moveTo(size * 0.52, size * 0.30)
          ..lineTo(size * 0.70, center.dy)
          ..lineTo(size * 0.52, size * 0.70))
        : (Path()
          ..moveTo(size * 0.22, center.dy)
          ..lineTo(size * 0.72, center.dy)
          ..moveTo(size * 0.56, size * 0.31)
          ..lineTo(size * 0.74, center.dy)
          ..lineTo(size * 0.56, size * 0.69));

    canvas.drawPath(path, outline);
    canvas.drawPath(path, stroke);
  }
}
