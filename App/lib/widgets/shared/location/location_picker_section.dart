import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../controllers/business/location_controller.dart';

class LocationPickerSection extends StatelessWidget {
  final LocationController locC;
  final LatLng defaultCenter;
  final Set<Polyline>? polylines;
  final bool mapError;
  final void Function(LatLng) onTap;

  const LocationPickerSection({
    super.key,
    required this.locC,
    required this.defaultCenter,
    required this.onTap,
    this.polylines,
    this.mapError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: locC.selected ?? defaultCenter,
                  zoom: 14,
                ),
                markers: locC.selected != null
                    ? {
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: locC.selected!,
                  ),
                }
                    : {},
                polylines: polylines ?? {},
                onTap: onTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                },
              ),
            ),
          ),
          if (mapError)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                "Debe seleccionar una ubicación.",
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      );
  }
}