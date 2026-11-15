import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../controllers/transport/public_transport_routes_controller.dart';
import '../../core/enums.dart';
import '../../helpers/transport_map_marker_helper.dart';
import '../../models/transport_line_model.dart';
import '../../models/transport_route_model.dart';
import '../../services/auth_service.dart';
import '../../services/transport_line_service.dart';
import '../../services/transport_route_service.dart';
import '../../ui/themes/colors.dart';
import '../../utils/transport/transport_line_color_manager.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/shared/transport/transport_legend.dart';

part '../../widgets/transport/public_routes/public_transport_selector_widgets.dart';
part '../../widgets/transport/public_routes/public_transport_detail.dart';
part '../../widgets/transport/public_routes/public_transport_common_widgets.dart';

class PublicTransportRoutesPage extends StatefulWidget {
  const PublicTransportRoutesPage({super.key});

  @override
  State<PublicTransportRoutesPage> createState() =>
      _PublicTransportRoutesPageState();
}

class _PublicTransportRoutesPageState extends State<PublicTransportRoutesPage> {
  static const LatLng _initialCenter = LatLng(-17.3936, -66.1570);

  late final PublicTransportRoutesController _controller;
  GoogleMapController? _mapController;
  bool _hasFitFirstSelection = false;
  bool _canUseUserLocation = false;
  int _markerBuildToken = 0;
  Set<Marker> _transportMarkers = {};

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _controller = PublicTransportRoutesController(
      lineService: TransportLineService(authService),
      routeService: TransportRouteService(authService),
    )
      ..addListener(_refreshTransportMarkers)
      ..loadLines();
    _syncLocationPermission();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _controller.removeListener(_refreshTransportMarkers);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleLine(TransportLineModel line) async {
    final hadSelection = _controller.selectedLineIds.isNotEmpty;
    final wasSelected = _controller.isSelected(line.id);
    final message = await _controller.toggleLine(line);

    if (!mounted) return;
    if (message != null) {
      showSnackbar(message, isError: true);
      return;
    }

    if (!wasSelected && !hadSelection && !_hasFitFirstSelection) {
      _hasFitFirstSelection = true;
      await _fitVisibleRoutes();
    }
  }

  Future<void> _fitVisibleRoutes({Iterable<int>? lineIds}) async {
    final points = _controller.visiblePoints(onlyLineIds: lineIds);
    if (_mapController == null || points.isEmpty) return;

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _mapController == null) return;

    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFromPoints(points), 56),
    );
  }

  Future<void> _centerOnUser() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      showSnackbar('Activa la ubicación para centrar el mapa');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _canUseUserLocation = false);
      showSnackbar('No se pudo acceder a tu ubicación', isError: true);
      return;
    }

    if (mounted && !_canUseUserLocation) {
      setState(() => _canUseUserLocation = true);
    }

    final position = await Geolocator.getCurrentPosition();
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15,
      ),
    );
  }

  Future<void> _syncLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;

    setState(() {
      _canUseUserLocation = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  void _openLineSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return _LineSelectorSheet(
              controller: _controller,
              scrollController: scrollController,
              onToggleLine: _toggleLine,
              onClose: () => Navigator.pop(context),
              onShowMap: () {
                Navigator.pop(context);
                _fitVisibleRoutes();
              },
            );
          },
        );
      },
    );
  }

  void _openDetails() {
    final selected = _controller.selectedLines;
    if (selected.isEmpty) {
      _openLineSelector();
      return;
    }

    if (selected.length == 1) {
      _showLineDetail(selected.first);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Selecciona una línea',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...selected.map(
              (line) => _TransportLineTile(
                line: line,
                selected: true,
                loading: _controller.isLoadingRoute(line.id),
                error: _controller.routeError(line.id),
                summary: _controller.routeSummary(line),
                onTap: () {
                  Navigator.pop(context);
                  _showLineDetail(line);
                },
                onRetry: () => _controller.ensureRouteLoaded(line.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLineDetail(TransportLineModel line) async {
    await _controller.ensureRouteLoaded(line.id);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TransportLineDetailPage(
          line: line,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isWide = MediaQuery.of(context).size.width >= 820;
        final panel = _LineSelectorPanel(
          controller: _controller,
          onToggleLine: _toggleLine,
          onShowMap: () => _fitVisibleRoutes(),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: 'Rutas y líneas',
            actions: [
              if (_controller.selectedLineIds.isNotEmpty)
                IconButton(
                  tooltip: 'Ajustar mapa',
                  onPressed: () => _fitVisibleRoutes(),
                  icon: const Icon(
                    Icons.center_focus_strong,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          body: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _initialCenter,
                        zoom: 13,
                      ),
                      polylines: _controller.buildPolylines(),
                      markers: _transportMarkers,
                      myLocationEnabled: _canUseUserLocation,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Column(
                        children: [
                          _MapActionButton(
                            icon: Icons.my_location,
                            tooltip: 'Mi ubicación',
                            onPressed: _centerOnUser,
                          ),
                          const SizedBox(height: 10),
                          if (_controller.selectedLineIds.isNotEmpty)
                            _MapActionButton(
                              icon: Icons.center_focus_strong,
                              tooltip: 'Ver rutas seleccionadas',
                              onPressed: () => _fitVisibleRoutes(),
                            ),
                        ],
                      ),
                    ),
                    if (!isWide)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _controller.selectedLineIds.isEmpty
                            ? _InitialBottomPanel(
                                onOpenSelector: _openLineSelector,
                              )
                            : _SelectedLinesBottomPanel(
                                controller: _controller,
                                onRemove: _controller.removeLine,
                                onClear: _controller.clearSelection,
                                onOpenSelector: _openLineSelector,
                                onDetails: _openDetails,
                              ),
                      ),
                  ],
                ),
              ),
              if (isWide)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: SizedBox(
                    width: 390,
                    child: panel,
                  ),
                ),
            ],
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  Future<void> _refreshTransportMarkers() async {
    final token = ++_markerBuildToken;
    final markers = await _buildSelectedRouteMarkers();
    if (!mounted || token != _markerBuildToken) return;
    setState(() => _transportMarkers = markers);
  }

  Future<Set<Marker>> _buildSelectedRouteMarkers() async {
    final markers = <Marker>{};

    for (final lineId in _controller.selectedLineIds) {
      final grouped = _controller.splitRoutes(lineId);
      final color = TransportLineColorManager.getBaseColor(lineId);
      final stopIcon = await TransportMapMarkerHelper.getIcon(
        type: TransportMapMarkerType.stop,
        color: color,
      );
      final startIcon = await TransportMapMarkerHelper.getIcon(
        type: TransportMapMarkerType.start,
        color: color,
      );
      final endIcon = await TransportMapMarkerHelper.getIcon(
        type: TransportMapMarkerType.end,
        color: color,
      );
      final arrowIcon = await TransportMapMarkerHelper.getIcon(
        type: TransportMapMarkerType.arrow,
        color: color,
      );

      for (final entry in grouped.entries) {
        final routes = entry.value;
        if (routes.isEmpty) continue;
        final first = routes.first;
        final last = routes.last;
        final directionName =
            entry.key == RouteDirection.outbound ? 'ida' : 'vuelta';

        for (final route in routes) {
          final isStart = route.id == first.id;
          final isEnd = route.id == last.id;
          markers.add(
            _stopMarker(
              lineId: lineId,
              route: route,
              directionName: directionName,
              label: isStart
                  ? 'Inicio'
                  : isEnd
                      ? 'Fin'
                      : 'Parada ${route.stopOrder}',
              icon: isStart
                  ? startIcon
                  : isEnd
                      ? endIcon
                      : stopIcon,
            ),
          );
        }

        markers.addAll(
          _directionArrowMarkers(
            lineId: lineId,
            routes: routes,
            directionName: directionName,
            icon: arrowIcon,
          ),
        );
      }
    }

    return markers;
  }

  Marker _stopMarker({
    required int lineId,
    required TransportRouteModel route,
    required String directionName,
    required String label,
    required BitmapDescriptor icon,
  }) {
    return Marker(
      markerId: MarkerId('line-$lineId-$directionName-stop-${route.id}'),
      position: LatLng(route.latitude, route.longitude),
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: '$label $directionName - Línea $lineId'),
    );
  }

  Iterable<Marker> _directionArrowMarkers({
    required int lineId,
    required List<TransportRouteModel> routes,
    required String directionName,
    required BitmapDescriptor icon,
  }) sync* {
    const minArrowSpacingMeters = 420.0;
    var distanceSinceArrow = minArrowSpacingMeters;

    for (var i = 0; i < routes.length - 1; i++) {
      final start = LatLng(routes[i].latitude, routes[i].longitude);
      final end = LatLng(routes[i + 1].latitude, routes[i + 1].longitude);
      final distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
      if (distance < 35) continue;

      distanceSinceArrow += distance;
      if (distanceSinceArrow < minArrowSpacingMeters) continue;

      distanceSinceArrow = 0;
      yield Marker(
        markerId: MarkerId('line-$lineId-$directionName-arrow-$i'),
        position: LatLng(
          (start.latitude + end.latitude) / 2,
          (start.longitude + end.longitude) / 2,
        ),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        rotation: (_bearing(start, end) - 90 + 360) % 360,
        zIndexInt: 1,
      );
    }
  }

  double _bearing(LatLng start, LatLng end) {
    final startLat = _degreesToRadians(start.latitude);
    final startLng = _degreesToRadians(start.longitude);
    final endLat = _degreesToRadians(end.latitude);
    final endLng = _degreesToRadians(end.longitude);
    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);
    return (_radiansToDegrees(math.atan2(y, x)) + 360) % 360;
  }

  double _degreesToRadians(double value) => value * math.pi / 180;

  double _radiansToDegrees(double value) => value * 180 / math.pi;
}
