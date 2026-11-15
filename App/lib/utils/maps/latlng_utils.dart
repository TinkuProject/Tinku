import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/transport_route_model.dart';

List<LatLng> removeDuplicateLatLng(List<LatLng> pts) {
  if (pts.length <= 1) return [];
  final out = <LatLng>[];
  LatLng? last;

  for (final p in pts) {
    if (last == null ||
        p.latitude != last.latitude ||
        p.longitude != last.longitude) {
      out.add(p);
      last = p;
    }
  }
  return out;
}

List<LatLng> toLatLngList(List<TransportRouteModel> routes) {
  return routes.map((r) {
    return LatLng(r.latitude, r.longitude);
  }).toList();
}