import 'package:flutter/material.dart';

import '../../../models/opening_hour_model.dart';
import '../../../core/enums.dart';
import '../../../services/opening_hour_service.dart';
import '../../../utils/date/time.utils.dart';
import '../../../domain/opening_hours.validator.dart';

class OpeningHoursController extends ChangeNotifier {
  OpeningHoursController(this._openingHourService);

  final OpeningHourService _openingHourService;
  bool enabled = true;

  final List<OpeningHourModel> _operatingHours = [];
  List<OpeningHourModel> get operatingHours => List.unmodifiable(_operatingHours);

  bool loading = false;

  OpeningEntity? _entityType;
  int? _entityId;

  // =========================
  // CONTEXT
  // =========================
  void setDraftContext({
    required OpeningEntity entityType,
  }) {
    _entityType = entityType;
    _entityId = null;
  }

  void setContext({
    required OpeningEntity entityType,
    required int entityId,
  }) {
    _entityType = entityType;
    _entityId = entityId;
  }

  void _ensureDraftContext() {
    if (_entityType == null) {
      throw Exception("OpeningHoursController: tipo de entidad no inicializado");
    }
  }

  void _ensureSaveContext() {
    if (_entityType == null || _entityId == null) {
      throw Exception("OpeningHoursController: contexto no inicializado");
    }
  }

  // =========================
  // LOAD
  // =========================
  Future<void> load({
    required OpeningEntity entityType,
    required int entityId,
  }) async {
    setContext(entityType: entityType, entityId: entityId);

    _operatingHours.clear();

    final hours = await _openingHourService.getByEntity(
      entityType: entityType,
      entityId: entityId,
    );

    _operatingHours.addAll(
      hours.map(
            (h) => h.copyWith(
          startTime: TimeUtils.normalize(h.startTime),
          endTime: TimeUtils.normalize(h.endTime),
        ),
      ),
    );

    notifyListeners();
  }

  void setLoaded({
    required OpeningEntity entityType,
    required int entityId,
    required List<OpeningHourModel> hours,
  }) {
    setContext(entityType: entityType, entityId: entityId);

    _operatingHours
      ..clear()
      ..addAll(
        hours.map(
          (h) => h.copyWith(
            startTime: TimeUtils.normalize(h.startTime),
            endTime: TimeUtils.normalize(h.endTime),
          ),
        ),
      );

    loading = false;
    notifyListeners();
  }

  // =========================
  // ADD
  // =========================
  void addHour({
    required WeekDay day,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    _ensureDraftContext();

    final newHour = OpeningHourModel(
      id: 0,
      entityId: _entityId ?? 0,
      entityType: _entityType!,
      weekDay: day,
      startTime: TimeUtils.format(start),
      endTime: TimeUtils.format(end),
    );

    OpeningHoursValidator.validateNewHour(
      _operatingHours,
      newHour,
    );

    _operatingHours.add(newHour);
    notifyListeners();
  }

  // =========================
  // REMOVE
  // =========================
  void removeHour(OpeningHourModel hour) {
    _operatingHours.remove(hour);
    notifyListeners();
  }

  // =========================
  // GROUPED (para UI)
  // =========================
  Map<WeekDay, List<OpeningHourModel>> get groupedHours {
    final map = <WeekDay, List<OpeningHourModel>>{};

    for (final h in _operatingHours) {
      map.putIfAbsent(h.weekDay, () => []).add(h);
    }

    for (final list in map.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return map;
  }

  // =========================
  // SAVE
  // =========================
  Future<void> save() async {
    _ensureSaveContext();

    loading = true;
    notifyListeners();

    try {
      await _openingHourService.replaceAll(
        entityType: _entityType!,
        entityId: _entityId!,
        hours: _operatingHours
            .map(
              (h) => h.copyWith(
            entityId: _entityId!,
            startTime: TimeUtils.normalize(h.startTime),
            endTime: TimeUtils.normalize(h.endTime),
          ),
        )
            .toList(),
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setEnabled(bool value) {
    enabled = value;

    if (!enabled) {
      _operatingHours.clear();
    }

    notifyListeners();
  }

  void applyWeekTemplate() {
    _ensureDraftContext();

    _operatingHours.clear();

    for (final day in WeekDay.values) {
      if (day == WeekDay.saturday || day == WeekDay.sunday) continue;

      _operatingHours.add(
        OpeningHourModel(
          id: 0,
          entityId: _entityId ?? 0,
          entityType: _entityType!,
          weekDay: day,
          startTime: "08:00",
          endTime: "18:00",
        ),
      );
    }

    notifyListeners();
  }

  void applyFullDay() {
    _ensureDraftContext();

    _operatingHours.clear();

    for (final day in WeekDay.values) {
      _operatingHours.add(
        OpeningHourModel(
          id: 0,
          entityId: _entityId ?? 0,
          entityType: _entityType!,
          weekDay: day,
          startTime: "00:00",
          endTime: "23:59",
        ),
      );
    }

    notifyListeners();
  }

  void clearAll() {
    _operatingHours.clear();
    notifyListeners();
  }

  void reset() {
    _operatingHours.clear();
    _entityType = null;
    _entityId = null;
    notifyListeners();
  }
}
