import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/transport_route_model.dart';
import '../../../models/entity_transport_relation_model.dart';
import '../../../models/transport_line_model.dart';
import '../../../core/enums.dart';

import '../../../services/transport_line_service.dart';
import '../../../services/entity_transport_relation_service.dart';
import '../../../services/transport_route_service.dart';

import '../../../helpers/transport_helper.dart';
import '../../../utils/maps/latlng_utils.dart';
import '../../../utils/transport/transport_line_color_manager.dart';

class EntityTransportController extends ChangeNotifier {
  EntityTransportController(
      this._transportService,
      this._relationService,
      this._routeService,
      );

  final TransportLineService _transportService;
  final EntityTransportRelationService _relationService;
  final TransportRouteService _routeService;

  // =========================
  // STATE
  // =========================
  Map<String, String> transportLines = {};
  List<String> entityTransportLines = [];
  List<String> selectedTransportLines = [];

  Map<String, List<TransportRouteModel>> routesByLine = {};
  Set<Polyline> polylines = {};

  bool loading = false;


  // =========================
  // CONTEXT
  // =========================
  void setContext({
    required VisitEntity entityType,
    required int entityId,
  }) {
  }

  Future<void> toggleTransportLine(String id) async {
    final list = List<String>.from(selectedTransportLines);

    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }

    await setSelected(list);
  }

  // =========================
  // LOAD AVAILABLE LINES
  // =========================
  Future<void> loadAvailable() async {
    final allLines = await _transportService.getAll();
    final activeLines = allLines
        .where((line) => line.status == BasicStatus.active)
        .toList();
    final routesMap = await _routeService.getByLines(
      lineIds: activeLines.map((line) => line.id).toList(),
    );
    final filtered = <String, String>{};

    for (final line in activeLines) {
      final routes = routesMap[line.id] ?? [];
      final out = routes
          .where((p) => p.direction == RouteDirection.outbound)
          .toList();

      final ret = routes
          .where((p) => p.direction == RouteDirection.return_)
          .toList();

      if (out.length > 1 || ret.length > 1) {
        filtered[line.id.toString()] = line.name;
      }
    }

    transportLines = filtered;
    notifyListeners();
  }

  // =========================
  // LOAD ROUTES + POLYLINES
  // =========================
  Future<void> loadRoutesForSelected() async {
    if (selectedTransportLines.isEmpty) {
      routesByLine.clear();
      polylines.clear();
      notifyListeners();
      return;
    }

    final lineIds = selectedTransportLines.map(int.parse).toList();
    final routesMap = await _routeService.getByLines(lineIds: lineIds);

    routesByLine = {
      for (final entry in routesMap.entries) entry.key.toString(): entry.value,
    };

    polylines = _buildPolylinesFromRoutes(routesByLine);

    notifyListeners();
  }

  // =========================
  // LOAD SELECTED
  // =========================
  Future<void> loadSelected({
    required VisitEntity entityType,
    required int entityId,
  }) async {
    setContext(entityType: entityType, entityId: entityId);

    selectedTransportLines.clear();
    entityTransportLines.clear();

    final relations = await _relationService.getByEntity(
      entityType: entityType,
      entityId: entityId,
    );

    entityTransportLines.addAll(
      relations.map((e) => e.transportLineId.toString()),
    );
    selectedTransportLines.addAll(entityTransportLines);

    await loadRoutesForSelected();

    notifyListeners();
  }

  Future<void> loadSelectedOnly({
    required VisitEntity entityType,
    required int entityId,
  }) async {
    setContext(entityType: entityType, entityId: entityId);

    selectedTransportLines.clear();
    entityTransportLines.clear();
    transportLines.clear();

    final relations = await _relationService.getByEntity(
      entityType: entityType,
      entityId: entityId,
    );

    final lineIds = relations
        .map((relation) => relation.transportLineId)
        .toSet()
        .toList();

    entityTransportLines.addAll(lineIds.map((id) => id.toString()));
    selectedTransportLines.addAll(entityTransportLines);

    if (lineIds.isNotEmpty) {
      final lines = await _transportService.getByIds(lineIds);
      transportLines = {
        for (final line in lines) line.id.toString(): line.name,
      };
    }

    await loadRoutesForSelected();

    notifyListeners();
  }

  void setLoaded({
    required List<EntityTransportRelationModel> relations,
    required List<TransportLineModel> lines,
    required Map<String, List<TransportRouteModel>> routes,
  }) {
    final lineIds = relations
        .map((relation) => relation.transportLineId)
        .toSet()
        .toList();

    entityTransportLines
      ..clear()
      ..addAll(lineIds.map((id) => id.toString()));
    selectedTransportLines
      ..clear()
      ..addAll(entityTransportLines);
    transportLines
      ..clear()
      ..addAll({
        for (final line in lines) line.id.toString(): line.name,
      });
    routesByLine
      ..clear()
      ..addAll(routes);
    polylines = _buildPolylinesFromRoutes(routesByLine);
    loading = false;
    notifyListeners();
  }

  // =========================
  // SET SELECTION
  // =========================
  Future<void> setSelected(List<String> values) async {
    selectedTransportLines = List<String>.from(values);
    await loadRoutesForSelected();
  }

  // =========================
  // SAVE
  // =========================
  Future<void> save({
    required int entityId,
    required VisitEntity entityType,
  }) async {
    loading = true;
    notifyListeners();

    try {
      await _relationService.replaceLines(
        entityType: entityType,
        entityId: entityId,
        newLineIds: selectedTransportLines.map(int.parse).toList(),
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // RESET
  // =========================
  void reset() {
    entityTransportLines.clear();
    selectedTransportLines.clear();
    routesByLine.clear();
    polylines.clear();
    notifyListeners();
  }


  void toggleLine(String id) {
    final newList = List<String>.from(selectedTransportLines);

    if (newList.contains(id)) {
      newList.remove(id);
    } else {
      newList.add(id);
    }

    setSelected(newList);
  }

  Set<Polyline> _buildPolylinesFromRoutes(
    Map<String, List<TransportRouteModel>> routes,
  ) {
    final Set<Polyline> newPolys = {};

    for (final entry in routes.entries) {
      final lineId = int.tryParse(entry.key);
      if (lineId == null) continue;

      final grouped = TransportHelper.splitAndSort(entry.value);

      final out = removeDuplicateLatLng(toLatLngList(
        grouped[RouteDirection.outbound] ?? [],
      ));

      final ret = removeDuplicateLatLng(toLatLngList(
        grouped[RouteDirection.return_] ?? [],
      ));

      final base = TransportLineColorManager.getBaseColor(lineId);

      if (out.length >= 2) {
        newPolys.add(Polyline(
          polylineId: PolylineId("line-$lineId-out"),
          points: out,
          color: base,
          width: 5,
        ));
      }

      if (ret.length >= 2) {
        newPolys.add(Polyline(
          polylineId: PolylineId("line-$lineId-ret"),
          points: ret,
          color: base.withValues(alpha: 0.5),
          width: 5,
        ));
      }
    }

    return newPolys;
  }
}
