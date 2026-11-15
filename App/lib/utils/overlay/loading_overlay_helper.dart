import 'package:flutter/material.dart';
import '../../widgets/overlays/loading_overlay.dart';

class LoadingOverlayHelper {
  static OverlayEntry? _currentOverlay;

  /// =========================
  /// SHOW
  /// =========================
  static void show(
      BuildContext context, {
        required String message,
        IconData? icon,
      }) {
    // Evita duplicados
    if (_currentOverlay != null) return;

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (_) => LoadingOverlay(
        message: message,
        icon: icon ?? Icons.hourglass_empty,
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  /// =========================
  /// HIDE
  /// =========================
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// =========================
  /// SAFE EXECUTION
  /// =========================
  static Future<T> runWithOverlay<T>(
      BuildContext context,
      Future<T> Function() task, {
        String message = "Procesando...",
        IconData? icon,
      }) async {
    try {
      show(context, message: message, icon: icon);
      final result = await task();
      return result;
    } finally {
      hide();
    }
  }
}