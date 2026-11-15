import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationController extends ChangeNotifier {
  LatLng mapCenter = const LatLng(-17.3936, -66.1570);
  LatLng? selected;
  String address = '';

  Future<void> onTap(LatLng pos) async {
    selected = pos;
    await _reverseGeocode(pos);
    notifyListeners();
  }

  Future<void> _reverseGeocode(LatLng p) async {
    try {
      final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (placemarks.isNotEmpty) {
        final x = placemarks.first;
        address = '${x.street ?? ''}, ${x.locality ?? ''}, ${x.country ?? ''}'.trim();
        return;
      }
    } catch (_) {}
    address = 'Ubicación: (${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)})';
  }

  Future<void> updateAddressFromLatLng(LatLng latLng) async {
    selected = latLng;
    await _reverseGeocode(latLng);
    notifyListeners();
  }

  /// ⚙️ Establece la ubicación inicial (para modo edición)
  void setInitialLocation(double? lat, double? lng, String addressText) {
    if (lat != null && lng != null) {
      selected = LatLng(lat, lng);
      mapCenter = LatLng(lat, lng);
      address = addressText;
      notifyListeners();
    }
  }

}
