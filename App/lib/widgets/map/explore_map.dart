import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/maps/map_utils.dart';

class ExploreMap extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline>? polylines;

  const ExploreMap({
    super.key,
    required this.markers,
    this.polylines,
  });

  @override
  State<ExploreMap> createState() => _ExploreMapState();
}

class _ExploreMapState extends State<ExploreMap> {
  GoogleMapController? _controller;

  bool _mapReady = false;
  bool _locationLoading = false;
  String _lastMarkerSignature = '';

  @override
  void didUpdateWidget(covariant ExploreMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller == null) return;

    final oldSignature = _markerSignature(oldWidget.markers);
    final nextSignature = _markerSignature(widget.markers);

    if (oldSignature == nextSignature) return;

    _lastMarkerSignature = '';

    /// 🔥 siempre que cambien markers → re-centrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMap();
    });
  }

  void _tryCenter() {
    if (!_mapReady || widget.markers.isEmpty) return;

    final signature = _markerSignature(widget.markers);
    if (_lastMarkerSignature == signature) return;

    _lastMarkerSignature = signature;

    Future.delayed(const Duration(milliseconds: 300), _centerMap);
  }

  String _markerSignature(Set<Marker> markers) {
    final ids = markers.map((m) => m.markerId.value).toList()..sort();
    return ids.join('|');
  }

  void _centerMap() {
    if (!mounted || _controller == null || widget.markers.isEmpty) return;

    // 🔥 caso 1: un solo marker
    if (widget.markers.length == 1) {
      final marker = widget.markers.first;

      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
      return;
    }

    // 🔥 múltiples markers
    final bounds = boundsFromMarkers(widget.markers);

    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  Future<void> _centerOnUserLocation() async {
    if (_controller == null || _locationLoading) return;

    setState(() => _locationLoading = true);

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos acceder a tu ubicación'),
          ),
        );
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activá la ubicación del dispositivo'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos centrar el mapa en tu ubicación'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            /// 🗺️ MAPA
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-17.3895, -66.1568),
                  zoom: 13,
                ),
                markers: widget.markers,
                polylines: widget.polylines ?? {},
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
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
              ),
            ),

            /// 🌑 GRADIENTE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            /// 🧭 TITULO
            const Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  Icon(Icons.explore, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Explorar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// 🎯 BOTÓN CENTRAR
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _centerOnUserLocation,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _locationLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location,
                            size: 20,
                            color: Colors.black87,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
