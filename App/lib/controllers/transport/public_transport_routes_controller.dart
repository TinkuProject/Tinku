import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/enums.dart';
import '../../helpers/transport_helper.dart';
import '../../models/transport_line_model.dart';
import '../../models/transport_route_model.dart';
import '../../services/transport_line_service.dart';
import '../../services/transport_route_service.dart';
import '../../utils/maps/latlng_utils.dart';
import '../../utils/transport/transport_line_color_manager.dart';

enum TransportRouteViewMode { outbound, return_, both }

class PublicTransportRoutesController extends ChangeNotifier {
  PublicTransportRoutesController({
    required TransportLineService lineService,
    required TransportRouteService routeService,
  })  : _lineService = lineService,
        _routeService = routeService;

  static const int maxVisibleLines = 6;

  final TransportLineService _lineService;
  final TransportRouteService _routeService;

  final Map<int, List<TransportRouteModel>> _routeCache = {};
  final Set<int> _selectedLineIds = {};
  final Set<int> _loadingRouteIds = {};
  final Map<int, String> _routeErrors = {};

  List<TransportLineModel> _lines = [];
  bool loadingLines = false;
  String? linesError;
  final ValueNotifier<String> queryChanges = ValueNotifier('');
  String get query => queryChanges.value;

  List<TransportLineModel> get lines => List.unmodifiable(_lines);
  Set<int> get selectedLineIds => Set.unmodifiable(_selectedLineIds);
  Set<int> get loadingRouteIds => Set.unmodifiable(_loadingRouteIds);
  Map<int, String> get routeErrors => Map.unmodifiable(_routeErrors);
  Map<int, List<TransportRouteModel>> get routeCache =>
      Map.unmodifiable(_routeCache);

  List<TransportLineModel> get selectedLines {
    return _selectedLineIds
        .map(lineById)
        .whereType<TransportLineModel>()
        .toList();
  }

  List<TransportLineModel> get filteredLines {
    final q = query.trim().toLowerCase();

    return _lines.where((line) {
      if (q.isEmpty) return true;

      return line.id.toString().contains(q) ||
          line.name.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> loadLines() async {
    loadingLines = true;
    linesError = null;
    notifyListeners();

    try {
      final result = await _lineService.getActiveWithRoutes();
      _lines = result..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      linesError = 'No se pudieron cargar las líneas';
    } finally {
      loadingLines = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    queryChanges.value = value;
  }

  @override
  void dispose() {
    queryChanges.dispose();
    super.dispose();
  }

  bool isSelected(int lineId) => _selectedLineIds.contains(lineId);
  bool isLoadingRoute(int lineId) => _loadingRouteIds.contains(lineId);
  String? routeError(int lineId) => _routeErrors[lineId];

  TransportLineModel? lineById(int id) {
    for (final line in _lines) {
      if (line.id == id) return line;
    }
    return null;
  }

  Future<String?> toggleLine(TransportLineModel line) async {
    if (_selectedLineIds.contains(line.id)) {
      removeLine(line.id);
      return null;
    }

    if (_selectedLineIds.length >= maxVisibleLines) {
      return 'No puedes visualizar más de $maxVisibleLines líneas al mismo tiempo';
    }

    _selectedLineIds.add(line.id);
    notifyListeners();

    await ensureRouteLoaded(line.id);
    return null;
  }

  Future<void> ensureRouteLoaded(int lineId) async {
    if (_routeCache.containsKey(lineId) || _loadingRouteIds.contains(lineId)) {
      return;
    }

    _loadingRouteIds.add(lineId);
    _routeErrors.remove(lineId);
    notifyListeners();

    try {
      final routes = await _routeService.getByLine(lineId);
      routes.sort((a, b) {
        final dir = a.direction.index.compareTo(b.direction.index);
        if (dir != 0) return dir;
        return a.stopOrder.compareTo(b.stopOrder);
      });

      if (routes.isEmpty) {
        _routeErrors[lineId] = 'Esta línea aún no tiene recorrido cargado';
      } else {
        _routeCache[lineId] = routes;
      }
    } catch (_) {
      _routeErrors[lineId] = 'No se pudo cargar la ruta';
    } finally {
      _loadingRouteIds.remove(lineId);
      notifyListeners();
    }
  }

  void removeLine(int lineId) {
    _selectedLineIds.remove(lineId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedLineIds.clear();
    notifyListeners();
  }

  Set<Polyline> buildPolylines({
    TransportRouteViewMode viewMode = TransportRouteViewMode.both,
    Iterable<int>? onlyLineIds,
  }) {
    final ids = onlyLineIds ?? _selectedLineIds;
    final polylines = <Polyline>{};

    for (final lineId in ids) {
      final routes = _routeCache[lineId] ?? [];
      if (routes.isEmpty) continue;

      final grouped = TransportHelper.splitAndSort(routes);
      final outbound = removeDuplicateLatLng(
        toLatLngList(grouped[RouteDirection.outbound] ?? []),
      );
      final returnRoute = removeDuplicateLatLng(
        toLatLngList(grouped[RouteDirection.return_] ?? []),
      );
      final base = TransportLineColorManager.getBaseColor(lineId);

      if (viewMode != TransportRouteViewMode.return_ && outbound.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('public-line-$lineId-outbound'),
            points: outbound,
            color: base,
            width: 5,
          ),
        );
      }

      if (viewMode != TransportRouteViewMode.outbound &&
          returnRoute.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('public-line-$lineId-return'),
            points: returnRoute,
            color: TransportLineColorManager.getReturnColor(lineId),
            width: 4,
          ),
        );
      }
    }

    return polylines;
  }

  List<LatLng> visiblePoints({Iterable<int>? onlyLineIds}) {
    final ids = onlyLineIds ?? _selectedLineIds;
    final points = <LatLng>[];

    for (final lineId in ids) {
      final routes = _routeCache[lineId] ?? [];
      points.addAll(
        routes.map((route) => LatLng(route.latitude, route.longitude)),
      );
    }

    return points;
  }

  String routeSummary(TransportLineModel line) {
    final routes = _routeCache[line.id];
    if (routes == null || routes.isEmpty) {
      return 'Origen y destino no registrados';
    }

    final grouped = TransportHelper.splitAndSort(routes);
    final outbound = grouped[RouteDirection.outbound] ?? [];
    if (outbound.length >= 2) {
      return 'Parada ${outbound.first.stopOrder} - Parada ${outbound.last.stopOrder}';
    }

    final returnRoute = grouped[RouteDirection.return_] ?? [];
    if (returnRoute.length >= 2) {
      return 'Parada ${returnRoute.first.stopOrder} - Parada ${returnRoute.last.stopOrder}';
    }

    return 'Recorrido parcial registrado';
  }

  Map<RouteDirection, List<TransportRouteModel>> splitRoutes(int lineId) {
    return TransportHelper.splitAndSort(_routeCache[lineId] ?? []);
  }
}
