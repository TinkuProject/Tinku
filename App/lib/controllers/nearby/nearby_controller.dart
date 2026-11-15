import 'package:flutter/material.dart';

import '../../models/nearby_item_model.dart';
import '../../services/nearby_service.dart';

class NearbyController extends ChangeNotifier {
  final NearbyService nearbyService;

  NearbyController({
    required this.nearbyService,
  });

  // =========================
  // STATE
  // =========================
  final List<NearbyItemModel> items = [];

  bool loading = false;
  String? error;

  double radius = 5000;

  // cache interno
  double? _lastLat;
  double? _lastLng;
  double? _lastRadius;

  // coords actuales (para no depender del UI)
  double? _lat;
  double? _lng;

  // =========================
  // LOAD
  // =========================
  Future<void> loadNearby({
    required double lat,
    required double lng,
    double radius = 5000,
  }) async {
    // evitar recargas innecesarias (incluye radius)
    if (_lastLat == lat &&
        _lastLng == lng &&
        _lastRadius == radius &&
        items.isNotEmpty) {
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await nearbyService.getNearby(
        lat: lat,
        lng: lng,
        radius: radius,
      );

      items
        ..clear()
        ..addAll(data);

      // guardar estado
      _lastLat = lat;
      _lastLng = lng;
      _lastRadius = radius;

      _lat = lat;
      _lng = lng;

      this.radius = radius;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // CHANGE RADIUS
  // =========================
  Future<void> setRadius(double newRadius) async {
    if (_lat == null || _lng == null) return;

    radius = newRadius;
    await loadNearby(
      lat: _lat!,
      lng: _lng!,
      radius: radius,
    );
  }

  // =========================
  // RESET
  // =========================
  void clear() {
    items.clear();
    error = null;

    _lastLat = null;
    _lastLng = null;
    _lastRadius = null;

    _lat = null;
    _lng = null;

    notifyListeners();
  }
}
