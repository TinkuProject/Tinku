import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TransportMap extends StatelessWidget {
  final double lat;
  final double lng;
  final String name;
  final Set<Polyline> polylines;

  const TransportMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.name,
    required this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 13,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("place"),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
            ),
          },
          polylines: polylines,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
            )
          },
        ),
      ),
    );
  }
}