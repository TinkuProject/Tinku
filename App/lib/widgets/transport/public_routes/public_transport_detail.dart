part of '../../../views/transport/public_transport_routes_page.dart';

class _TransportLineDetailPage extends StatefulWidget {
  const _TransportLineDetailPage({
    required this.line,
    required this.controller,
  });

  final TransportLineModel line;
  final PublicTransportRoutesController controller;

  @override
  State<_TransportLineDetailPage> createState() =>
      _TransportLineDetailPageState();
}

class _TransportLineDetailPageState extends State<_TransportLineDetailPage> {
  GoogleMapController? _mapController;
  TransportRouteViewMode _viewMode = TransportRouteViewMode.both;
  int _markerBuildToken = 0;
  Set<Marker> _directionMarkers = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshDirectionMarkers);
    _refreshDirectionMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    widget.controller.removeListener(_refreshDirectionMarkers);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final color = TransportLineColorManager.getBaseColor(line.id);
    final grouped = widget.controller.splitRoutes(line.id);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final polylines = widget.controller.buildPolylines(
          viewMode: _viewMode,
          onlyLineIds: [line.id],
        );

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(line.name),
            ),
            body: Column(
              children: [
                SizedBox(
                  height: 245,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _PublicTransportRoutesPageState._initialCenter,
                      zoom: 13,
                    ),
                    polylines: polylines,
                    markers: _directionMarkers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitLine();
                    },
                  ),
                ),
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              line.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.controller.routeSummary(line),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const TransportLegend(),
                      const SizedBox(height: 10),
                      const TabBar(
                        labelColor: AppColors.darkBlue,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.darkBlue,
                        tabs: [
                          Tab(text: 'Resumen'),
                          Tab(text: 'Paradas'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _SummaryTab(
                        line: line,
                        controller: widget.controller,
                        onFitRoute: _fitLine,
                      ),
                      _StopsTab(
                        grouped: grouped,
                        viewMode: _viewMode,
                        onChanged: (mode) {
                          setState(() => _viewMode = mode);
                          _refreshDirectionMarkers();
                          _fitLine();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fitLine() async {
    final points =
        widget.controller.visiblePoints(onlyLineIds: [widget.line.id]);
    if (_mapController == null || points.isEmpty) return;

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFromPoints(points), 46),
    );
  }

  Future<void> _refreshDirectionMarkers() async {
    final token = ++_markerBuildToken;
    final color = TransportLineColorManager.getBaseColor(widget.line.id);
    final icon = await TransportMapMarkerHelper.getIcon(
      type: TransportMapMarkerType.chevron,
      color: color,
    );
    final markers = _buildDetailDirectionMarkers(icon);

    if (!mounted || token != _markerBuildToken) return;
    setState(() => _directionMarkers = markers);
  }

  Set<Marker> _buildDetailDirectionMarkers(BitmapDescriptor icon) {
    final grouped = widget.controller.splitRoutes(widget.line.id);
    final markers = <Marker>{};

    if (_viewMode != TransportRouteViewMode.return_) {
      markers.addAll(
        _chevronMarkers(
          routes: grouped[RouteDirection.outbound] ?? [],
          directionName: 'ida',
          icon: icon,
        ),
      );
    }

    if (_viewMode != TransportRouteViewMode.outbound) {
      markers.addAll(
        _chevronMarkers(
          routes: grouped[RouteDirection.return_] ?? [],
          directionName: 'vuelta',
          icon: icon,
        ),
      );
    }

    return markers;
  }

  Iterable<Marker> _chevronMarkers({
    required List<TransportRouteModel> routes,
    required String directionName,
    required BitmapDescriptor icon,
  }) sync* {
    const minSpacingMeters = 300.0;
    var distanceSinceChevron = minSpacingMeters;

    for (var i = 0; i < routes.length - 1; i++) {
      final start = LatLng(routes[i].latitude, routes[i].longitude);
      final end = LatLng(routes[i + 1].latitude, routes[i + 1].longitude);
      final distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
      if (distance < 30) continue;

      distanceSinceChevron += distance;
      if (distanceSinceChevron < minSpacingMeters) continue;

      distanceSinceChevron = 0;
      yield Marker(
        markerId: MarkerId(
          'line-${widget.line.id}-$directionName-detail-chevron-$i',
        ),
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

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.line,
    required this.controller,
    required this.onFitRoute,
  });

  final TransportLineModel line;
  final PublicTransportRoutesController controller;
  final VoidCallback onFitRoute;

  @override
  Widget build(BuildContext context) {
    final pointCount = controller.visiblePoints(onlyLineIds: [line.id]).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Línea', value: line.name),
        _InfoRow(
          label: 'Recorrido registrado',
          value: controller.routeSummary(line),
        ),
        _InfoRow(
          label: 'Puntos del recorrido',
          value: '$pointCount puntos registrados',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.darkBlue,
            foregroundColor: AppColors.pureWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onFitRoute,
          icon: const Icon(Icons.route),
          label: const Text('Ver ruta completa'),
        ),
      ],
    );
  }
}

class _StopsTab extends StatelessWidget {
  const _StopsTab({
    required this.grouped,
    required this.viewMode,
    required this.onChanged,
  });

  final Map<RouteDirection, List<TransportRouteModel>> grouped;
  final TransportRouteViewMode viewMode;
  final ValueChanged<TransportRouteViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final outbound = grouped[RouteDirection.outbound] ?? [];
    final returnRoute = grouped[RouteDirection.return_] ?? [];
    final showOutbound = viewMode != TransportRouteViewMode.return_;
    final showReturn = viewMode != TransportRouteViewMode.outbound;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ModeChip(
              label: 'Solo ida',
              selected: viewMode == TransportRouteViewMode.outbound,
              onTap: () => onChanged(TransportRouteViewMode.outbound),
            ),
            _ModeChip(
              label: 'Solo vuelta',
              selected: viewMode == TransportRouteViewMode.return_,
              onTap: () => onChanged(TransportRouteViewMode.return_),
            ),
            _ModeChip(
              label: 'Ambos',
              selected: viewMode == TransportRouteViewMode.both,
              onTap: () => onChanged(TransportRouteViewMode.both),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (showOutbound) _StopGroup(title: 'Paradas de ida', routes: outbound),
        if (showOutbound && showReturn) const SizedBox(height: 18),
        if (showReturn)
          _StopGroup(title: 'Paradas de vuelta', routes: returnRoute),
      ],
    );
  }
}

class _StopGroup extends StatelessWidget {
  const _StopGroup({
    required this.title,
    required this.routes,
  });

  final String title;
  final List<TransportRouteModel> routes;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return _StateMessage(
        icon: Icons.route_outlined,
        title: '$title no registradas',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...routes.map((route) {
          final direction =
              route.direction == RouteDirection.outbound ? 'Ida' : 'Vuelta';
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.darkBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        route.stopOrder.toString(),
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parada ${route.stopOrder}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$direction - ${route.latitude.toStringAsFixed(5)}, ${route.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
