import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/event_model.dart';
import '../../models/business_model.dart';

import '../../services/event_service.dart';
import '../../services/business_service.dart';
import '../../services/media_service.dart';
import '../../services/category_service.dart';
import '../../services/review_service.dart';

import '../../ui/enums/event_filters.dart';

class EventsListController extends ChangeNotifier {
  EventsListController(
      this._eventService,
      this._businessService,
      this._mediaService,
      this._categoryService,
      this._reviewService,
      );

  final EventService _eventService;
  final BusinessService _businessService;
  final MediaService _mediaService;
  final CategoryService _categoryService;
  final ReviewService _reviewService;

  // =========================
  // UI STATE
  // =========================
  final TextEditingController searchCtrl = TextEditingController();
  String query = '';

  // =========================
  // DATA
  // =========================
  bool loading = true;
  String? error;
  List<EventModel> all = [];

  EventFilterStatus filterStatus = EventFilterStatus.all;
  EventOrder filterOrder = EventOrder.newest;
  EventPriceFilter filterPrice = EventPriceFilter.all;

  // =========================
  // CACHE
  // =========================
  final Map<int, BusinessModel?> _businessCache = {};
  Map<int, String> _categoryNameCache = {};
  final Map<int, List<String>> _mediaByEvent = {};
  final Map<int, String> _organizerCache = {};
  final Map<int, double> _ratingCache = {};

  Map<int, List<String>> get mediaByEvent => _mediaByEvent;

  // =========================
  // INIT
  // =========================
  Future<void> init() async {
    searchCtrl.addListener(() {
      query = searchCtrl.text.trim();
      notifyListeners();
    });

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
      all = await _eventService.getMine();

      final ids = all.map((e) => e.id).toList();

      // =========================
      // MEDIA
      // =========================
      if (ids.isNotEmpty) {
        final mediaMap = await _mediaService.getByEntities(
          entityIds: ids,
          entityType: MediaEntityType.event,
        );

        _mediaByEvent.clear();

        for (final entry in mediaMap.entries) {
          _mediaByEvent[entry.key] =
              entry.value.map((m) => m.url).toList();
        }
      }

      // =========================
      // CATEGORIES
      // =========================
      final categoryIds =
      all.map((e) => e.categoryId).toSet().toList();

      if (categoryIds.isNotEmpty) {
        _categoryNameCache =
        await _categoryService.getNamesByIds(categoryIds);
      }

      // =========================
      // ORGANIZADORES
      // =========================
      _organizerCache.clear();

      for (final e in all) {
        if (e.businessId != null) {
          final b = await getBusiness(e.businessId!);
          _organizerCache[e.id] = b?.name ?? "Negocio";
        } else {
          _organizerCache[e.id] = "Personal";
        }
      }

      // =========================
      // REVIEWS (RATING)
      // =========================
      if (ids.isNotEmpty) {
        final reviewMap = await _reviewService.getByEntities(
          entityType: ReviewEntityType.event,
          entityIds: ids,
        );

        _ratingCache.clear();

        for (final entry in reviewMap.entries) {
          final list = entry.value;

          if (list.isEmpty) continue;

          final avg = list
              .map((r) => r.rating)
              .reduce((a, b) => a + b) /
              list.length;

          _ratingCache[entry.key] =
              double.parse(avg.toStringAsFixed(1));
        }
      }

    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // FILTERS
  // =========================
  void setFilterStatus(EventFilterStatus v) {
    filterStatus = v;
    notifyListeners();
  }

  void setFilterOrder(EventOrder v) {
    filterOrder = v;
    notifyListeners();
  }

  void setFilterPrice(EventPriceFilter v) {
    filterPrice = v;
    notifyListeners();
  }

  // =========================
  // FILTERED LIST
  // =========================
  List<EventModel> get filtered {
    var list = [...all];
    final now = DateTime.now();

    if (query.isNotEmpty) {
      final q = query.toLowerCase();

      list = list.where((e) {
        final name = e.name.toLowerCase();
        final category =
        (_categoryNameCache[e.categoryId] ?? '').toLowerCase();

        return name.contains(q) || category.contains(q);
      }).toList();
    }

    switch (filterStatus) {
      case EventFilterStatus.upcoming:
        list = list
            .where((e) =>
                e.status == EventStatus.active && e.startDate.isAfter(now))
            .toList();
        break;
      case EventFilterStatus.past:
        list = list
            .where((e) =>
                e.status == EventStatus.finished ||
                (e.status == EventStatus.active && e.endDate.isBefore(now)))
            .toList();
        break;
      case EventFilterStatus.pending:
        list = list.where((e) => e.status == EventStatus.pending).toList();
        break;
      case EventFilterStatus.approved:
        list = list.where((e) => e.status == EventStatus.active).toList();
        break;
      case EventFilterStatus.rejected:
        list = list.where((e) => e.status == EventStatus.cancelled).toList();
        break;
      case EventFilterStatus.all:
        break;
    }

    switch (filterPrice) {
      case EventPriceFilter.free:
        list = list.where((e) => (e.tinkuPrice ?? 0) == 0).toList();
        break;
      case EventPriceFilter.paid:
        list = list.where((e) => (e.tinkuPrice ?? 0) > 0).toList();
        break;
      case EventPriceFilter.all:
        break;
    }

    if (filterOrder == EventOrder.newest) {
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
    } else {
      list.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    return list;
  }

  // =========================
  // HELPERS
  // =========================
  Future<BusinessModel?> getBusiness(int id) async {
    if (_businessCache.containsKey(id)) return _businessCache[id];

    final b = await _businessService.getById(id);
    _businessCache[id] = b;
    return b;
  }

  String categoryLabel(int categoryId) {
    return _categoryNameCache[categoryId] ?? 'Categoría';
  }

  String organizerLabel(int eventId) {
    return _organizerCache[eventId] ?? "Organizador";
  }

  double? getRating(int eventId) {
    return _ratingCache[eventId];
  }

  // =========================
  // STATUS (REAL + UX)
  // =========================
  ({String label, Color color, IconData icon}) statusMeta(EventModel e) {
    final now = DateTime.now();

    /// 1. CANCELADO (máxima prioridad)
    if (e.status == EventStatus.cancelled) {
      return (
      label: 'Cancelado',
      color: Colors.red,
      icon: Icons.cancel,
      );
    }

    /// 2. PENDIENTE (NO aprobado)
    if (e.status == EventStatus.pending) {
      return (
      label: 'Pendiente',
      color: Colors.orange,
      icon: Icons.hourglass_empty,
      );
    }

    /// 3. ACTIVE → aquí sí usamos fechas
    if (e.status == EventStatus.active) {

      if (e.endDate.isBefore(now)) {
        return (
        label: 'Finalizado',
        color: Colors.grey,
        icon: Icons.flag,
        );
      }

      if (e.startDate.isAfter(now)) {
        return (
        label: 'Próximo',
        color: Colors.blue,
        icon: Icons.schedule,
        );
      }

      return (
      label: 'En curso',
      color: Colors.green,
      icon: Icons.play_circle,
      );
    }

    /// 4. FINISHED (por si backend lo usa)
    if (e.status == EventStatus.finished) {
      return (
      label: 'Finalizado',
      color: Colors.grey,
      icon: Icons.flag,
      );
    }

    /// fallback
    return (
    label: 'Sin estado',
    color: Colors.grey,
    icon: Icons.help,
    );
  }

  bool canManageEvent(EventModel e) {
    return e.status == EventStatus.pending ||
        e.status == EventStatus.active;
  }

  // =========================
  // DELETE
  // =========================
  Future<void> softDeleteEvent(int id) async {
    try {
      final updated = await _eventService.softDeleteEvent(id);
      _replaceInList(all, updated);

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  void _replaceInList(
      List<EventModel> list,
      EventModel updated,
      ) {
    final index = list.indexWhere(
          (e) => e.id == updated.id,
    );

    if (index != -1) {
      list[index] = updated;
    }
  }

  void _clearData() {
    all = [];
    _businessCache.clear();
    _categoryNameCache = {};
    _mediaByEvent.clear();
    _organizerCache.clear();
    _ratingCache.clear();
  }

  void reset() {
    _clearData();
    query = '';
    searchCtrl.clear();
    filterStatus = EventFilterStatus.all;
    filterOrder = EventOrder.newest;
    filterPrice = EventPriceFilter.all;
    loading = false;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}
