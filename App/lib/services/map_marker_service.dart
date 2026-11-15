import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../helpers/marker_helper.dart';
import '../ui/themes/colors.dart';

class MapMarkerService {
  static Future<Set<Marker>> buildMarkers({
    required List<dynamic> businesses,
    required List<dynamic> touristPlaces,
    required List<dynamic> events,
  }) async {
    final Set<Marker> markers = {};

    for (final b in businesses) {
      const type = 'business';

      final icon = await MarkerHelper.getMarker(
        type,
        color: getColorByType(type),
      );

      markers.add(
        Marker(
          markerId: MarkerId('business_${b.id}'),
          position: LatLng(b.latitude, b.longitude),
          icon: icon,
          infoWindow: InfoWindow(title: b.name),
        ),
      );
    }

    for (final p in touristPlaces) {
      const type = 'tourist_place';

      final icon = await MarkerHelper.getMarker(
        type,
        color: getColorByType(type),
      );

      markers.add(
        Marker(
          markerId: MarkerId('tourist_${p.id}'),
          position: LatLng(p.latitude, p.longitude),
          icon: icon,
          infoWindow: InfoWindow(title: p.name),
        ),
      );
    }

    for (final e in events) {
      const type = 'event';

      final icon = await MarkerHelper.getMarker(
        type,
        color: getColorByType(type),
      );

      markers.add(
        Marker(
          markerId: MarkerId('event_${e.id}'),
          position: LatLng(e.latitude, e.longitude),
          icon: icon,
          infoWindow: InfoWindow(title: e.name),
        ),
      );
    }

    return markers;
  }
}

Color getColorByType(String type) {
  switch (type) {
    case 'business':
      return AppColors.navyBlue;

    case 'tourist_place':
      return AppColors.mediumBlue;

    case 'event':
      return AppColors.darkBlue;

    case 'service':
      return AppColors.electricBlue;

    case 'warehouse':
      return AppColors.emerald;

    default:
      return AppColors.softBlue;
  }
}
