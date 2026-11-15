import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/maps/map_utils.dart';

class FullMap extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline>? polylines;
  final MapType mapType;

  const FullMap({
    super.key,
    required this.markers,
    this.polylines,
    this.mapType = MapType.normal,
  });

  @override
  State<FullMap> createState() => _FullMapState();
}

class _FullMapState extends State<FullMap> {
  GoogleMapController? _controller;

  bool _mapReady = false;
  int _lastMarkerCount = 0;

  @override
  void didUpdateWidget(covariant FullMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryCenter();
  }

  void _tryCenter() {
    if (!_mapReady || widget.markers.isEmpty) return;

    if (_lastMarkerCount == widget.markers.length) return;

    _lastMarkerCount = widget.markers.length;

    Future.delayed(const Duration(milliseconds: 300), _centerMap);
  }

  void _centerMap() {
    if (!mounted || _controller == null || widget.markers.isEmpty) return;

    if (widget.markers.length == 1) {
      final marker = widget.markers.first;
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
      return;
    }

    final bounds = boundsFromMarkers(widget.markers);

    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-17.3936, -66.1570),
        zoom: 13,
      ),
      markers: widget.markers,
      polylines: widget.polylines ?? {},
      mapType: widget.mapType,
      myLocationEnabled: true,
      zoomControlsEnabled: true,
      myLocationButtonEnabled: true,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
        ),
      },
      onMapCreated: (controller) {
        _controller = controller;
        _mapReady = true;
        _tryCenter();
      },
    );
  }
}