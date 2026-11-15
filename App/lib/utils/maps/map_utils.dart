import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLngBounds boundsFromMarkers(Set<Marker> markers) {
  final latitudes = markers.map((m) => m.position.latitude).toList();
  final longitudes = markers.map((m) => m.position.longitude).toList();

  final south = latitudes.reduce((a, b) => a < b ? a : b);
  final north = latitudes.reduce((a, b) => a > b ? a : b);
  final west = longitudes.reduce((a, b) => a < b ? a : b);
  final east = longitudes.reduce((a, b) => a > b ? a : b);

  return LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
}