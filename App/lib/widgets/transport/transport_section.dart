import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/shared/transport/entity_transport_controller.dart';
import '../../ui/themes/colors.dart';
import '../../utils/transport/transport_line_color_manager.dart';
import '../common/empty/app_empty.dart';
import 'transport_chip_selector.dart';

class TransportSection extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String placeName;
  final EntityTransportController controller;

  const TransportSection({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final allLines = controller.transportLines;
    final entityLines = controller.entityTransportLines;
    final selectedLines = controller.selectedTransportLines;
    final polylines = controller.polylines;

    final visibleLines = Map<String, String>.fromEntries(
      entityLines
          .where((id) => allLines.containsKey(id))
          .map((id) => MapEntry(id, allLines[id]!)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (visibleLines.isEmpty)
          const AppEmptyState(
            icon: Icons.directions_bus_filled_outlined,
            title: 'Sin líneas cercanas',
            subtitle:
                'Aún no encontramos recorridos de transporte asociados a este lugar.',
            iconColor: AppColors.darkBlue,
          )
        else
          TransportChipSelector(
            transportLines: visibleLines,
            selectedLines: selectedLines.where(visibleLines.containsKey).toList(),
            controller: controller,
            lineColor: (lineId) => TransportLineColorManager.getBaseColor(
              int.parse(lineId),
            ),
          ),

        const SizedBox(height: 12),

        if (visibleLines.isNotEmpty)
          const Text(
            "Los colores de las líneas coinciden con los recorridos dibujados en el mapa.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.35,
            ),
          ),

        if (visibleLines.isNotEmpty)
          const SizedBox(height: 12),

        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("place"),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(title: placeName),
                ),
              },
              polylines: polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}
