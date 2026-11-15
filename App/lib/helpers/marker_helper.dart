import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerHelper {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> getMarker(
      String type, {
        required Color color,
        double size = 60,
      }) async {
    final key = '${type}_${color.toARGB32()}_$size';

    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final icon = _getIconByType(type);
      const pixelRatio = 3.0;
      final imageSize = (size * pixelRatio).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio);

      final center = Offset(size / 2, size / 2);

      final paint = Paint()..color = color;

      // círculo
      canvas.drawCircle(center, size * 0.32, paint);

      // punta
      final path = Path()
        ..moveTo(center.dx - size * 0.13, center.dy + size * 0.25)
        ..lineTo(center.dx + size * 0.13, center.dy + size * 0.25)
        ..lineTo(center.dx, center.dy + size * 0.55)
        ..close();

      canvas.drawPath(path, paint);

      // icono centrado REAL
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: size * 0.4,
            fontFamily: icon.fontFamily,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final iconOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, iconOffset);

      final picture = recorder.endRecording();
      final image = await picture.toImage(imageSize, imageSize);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Error generando marker');
      }

      final bitmap = BitmapDescriptor.bytes(
        byteData.buffer.asUint8List(),
        imagePixelRatio: pixelRatio,
      );

      _cache[key] = bitmap;

      return bitmap;
    } catch (_) {
      // fallback seguro
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }
  }

  static IconData _getIconByType(String type) {
    switch (type) {
      case 'business':
        return Icons.store;
      case 'tourist_place':
        return Icons.place;
      case 'event':
        return Icons.event;
      case 'service':
        return Icons.miscellaneous_services;
      case 'warehouse':
        return Icons.warehouse_outlined;
      case 'charging_point':
        return Icons.ev_station;
      default:
        return Icons.location_on;
    }
  }
}
