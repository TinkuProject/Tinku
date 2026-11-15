import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/enums.dart';
import '../../models/event_model.dart';
import '../../models/media_model.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';
import '../../services/reservation_service.dart';

class MyCalendarController extends ChangeNotifier {
  final EventService _eventSvc;
  final ReservationService _reservationSvc;
  final MediaService _mediaSvc;

  MyCalendarController(
    this._eventSvc,
    this._reservationSvc,
    this._mediaSvc,
  );

  // =========================
  // STATE
  // =========================
  bool loading = false;
  String? error;

  late DateTime focusedDay;
  DateTime? selectedDay;
  CalendarFormat format = CalendarFormat.month;

  List<EventModel> all = [];
  Map<DateTime, List<EventModel>> eventsByDay = {};
  Map<int, List<MediaModel>> mediaByEvent = {};

  // =========================
  // INIT
  // =========================
  Future<void> init() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    focusedDay = today;
    selectedDay = today;

    await refresh();
  }

  // =========================
  // REFRESH
  // =========================
  Future<void> refresh() async {
    loading = true;
    error = null;
    _clearData();
    notifyListeners();

    try {
      final organized = await _eventSvc.getMine();

      final reservations = await _reservationSvc.getMine();

      final confirmedReservations = reservations
          .where(
            (r) => r.status == ReservationStatus.confirmed,
          )
          .toList();

      final reservedEventIds =
          confirmedReservations.map((r) => r.eventId).toSet().toList();

      List<EventModel> reserved = [];
      if (reservedEventIds.isNotEmpty) {
        reserved = await _eventSvc.getByIds(reservedEventIds);
      }

      final map = <int, EventModel>{};

      for (final e in organized) {
        map[e.id] = e;
      }

      for (final e in reserved) {
        map[e.id] = e;
      }

      all = map.values.toList();

      eventsByDay.clear();

      for (final e in all) {
        DateTime current =
            DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
        final end = DateTime(e.endDate.year, e.endDate.month, e.endDate.day);

        while (!current.isAfter(end)) {
          eventsByDay.putIfAbsent(current, () => []).add(e);
          current = current.add(const Duration(days: 1));
        }
      }

      mediaByEvent.clear();

      final ids = all.map((e) => e.id).toList();

      if (ids.isNotEmpty) {
        final mediaMap = await _mediaSvc.getByEntities(
          entityIds: ids,
          entityType: MediaEntityType.event,
        );
        mediaByEvent = mediaMap;
      }
    } catch (err) {
      error = err.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // UI HELPERS
  // =========================
  void setFormat(CalendarFormat f) {
    format = f;
    notifyListeners();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    notifyListeners();
  }

  void onPageChanged(DateTime focused) {
    focusedDay = focused;
  }

  List<EventModel> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return eventsByDay[key] ?? [];
  }

  EventModel? nextEventAfter(DateTime selected, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final selectedStart = DateTime(selected.year, selected.month, selected.day);
    final upcoming = all
        .where((event) =>
            event.endDate.isAfter(currentTime) &&
            !event.startDate.isBefore(selectedStart))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return upcoming.isEmpty ? null : upcoming.first;
  }

  bool isMultiDay(EventModel e) {
    return e.endDate.difference(e.startDate).inDays > 0;
  }

  String monthYearEs() {
    final formatter = DateFormat('MMMM y', 'es');
    return formatter.format(focusedDay);
  }

  List<EventModel> get pastEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((e) {
      final end = e.endDate.toLocal();
      final endDay = DateTime(end.year, end.month, end.day);
      return endDay.isBefore(today);
    }).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
  }

  void _clearData() {
    all = [];
    eventsByDay.clear();
    mediaByEvent.clear();
  }

  void reset() {
    _clearData();
    loading = false;
    error = null;
    notifyListeners();
  }
}
