import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinkuapp/core/enums.dart';

import '../../models/business_model.dart';
import '../../models/event_model.dart';
import '../../models/tourist_place_model.dart';
import '../../models/category_model.dart';

import '../../services/map_marker_service.dart';
import '../../services/explore_feed_service.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExploreController extends ChangeNotifier {
  ExploreController(this._exploreFeedService);

  final ExploreFeedService _exploreFeedService;

  // =========================
  // STATE
  // =========================
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = false;
  int totalResults = 0;
  String? error;
  static const int _pageSize = 20;
  int _offset = 0;
  int _feedRequestId = 0;
  Timer? _searchDebounce;

  List<BusinessModel> allBusinesses = [];
  List<TouristPlaceModel> allTouristPlaces = [];
  List<EventModel> allEvents = [];
  List<CategoryModel> allCategories = [];

  // =========================
  // FILTER STATE
  // =========================
  String selectedType = 'Todos';
  int? selectedCategoryId;
  String query = '';

  final TextEditingController searchCtrl = TextEditingController();

  // =========================
  // CACHE
  // =========================
  final Map<int, String?> _businessImage = {};
  final Map<int, String?> _touristImage = {};
  final Map<int, String?> _eventImage = {};

  final Map<int, String> _categoryName = {};

  final Map<int, double> _ratingCache = {};
  final Map<int, double?> _priceCache = {};

  Set<Marker> markers = {};
  int _markerRequestId = 0;

  // =========================
  // INIT
  // =========================
  Future<void> init() async {
    searchCtrl.addListener(() {
      query = searchCtrl.text.trim();
      _searchDebounce?.cancel();
      _searchDebounce = Timer(
        const Duration(milliseconds: 350),
        () => unawaited(_reloadForFilters()),
      );
      notifyListeners();
    });

    await refresh();
  }

  void updateType(String type) {
    selectedType = type;
    selectedCategoryId = null;
    unawaited(_reloadForFilters());
    notifyListeners();
  }

  void updateCategory(int? id) {
    selectedCategoryId = id;
    unawaited(_reloadForFilters());
    notifyListeners();
  }

  // =========================
  // REFRESH
  // =========================
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _loadFromFeed(reset: true);
      await _loadMarkers();
    } catch (_) {
      error = 'No se pudo cargar Explorar. Desliza para reintentar.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFeed({required bool reset}) async {
    final requestId = ++_feedRequestId;
    final nextOffset = reset ? 0 : _offset + _pageSize;
    final feed = await _exploreFeedService.getFeed(
      limit: _pageSize,
      offset: nextOffset,
      query: query,
      type: selectedType == 'Todos' ? 'all' : selectedType,
      categoryId: selectedCategoryId,
    );

    if (requestId != _feedRequestId) return;

    allBusinesses = reset
        ? feed.businesses
        : _appendUnique(allBusinesses, feed.businesses, (item) => item.id);
    allCategories = feed.categories;
    allTouristPlaces = reset
        ? feed.touristPlaces
        : _appendUnique(
            allTouristPlaces,
            feed.touristPlaces,
            (item) => item.id,
          );
    allEvents = reset
        ? feed.events
        : _appendUnique(allEvents, feed.events, (item) => item.id);
    _offset = feed.offset;
    hasMore = feed.hasMore;
    totalResults = feed.total;

    _categoryName
      ..clear()
      ..addEntries(allCategories.map((c) => MapEntry(c.id, c.name)));

    _businessImage.addAll(feed.businessImages);
    _touristImage.addAll(feed.touristImages);
    _eventImage.addAll(feed.eventImages);
    _ratingCache.addAll(feed.businessRatings);
    _priceCache.addAll(feed.businessPrices);

    if (reset) {
      _retainCurrentCacheEntries();
    }
  }

  Future<void> _reloadForFilters() async {
    error = null;
    try {
      await _loadFromFeed(reset: true);
      await _reloadMarkersForFilters();
    } catch (_) {
      error = 'No se pudieron actualizar los resultados.';
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();

    try {
      await _loadFromFeed(reset: false);
      await _reloadMarkersForFilters();
    } catch (_) {
      error = 'No se pudieron cargar más resultados.';
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  List<T> _appendUnique<T>(
    List<T> current,
    List<T> incoming,
    int Function(T) idOf,
  ) {
    final result = [...current];
    final ids = current.map(idOf).toSet();
    for (final item in incoming) {
      if (ids.add(idOf(item))) result.add(item);
    }
    return result;
  }

  void _retainCurrentCacheEntries() {
    final businessIds = allBusinesses.map((item) => item.id).toSet();
    final touristIds = allTouristPlaces.map((item) => item.id).toSet();
    final eventIds = allEvents.map((item) => item.id).toSet();
    _businessImage.removeWhere((id, _) => !businessIds.contains(id));
    _touristImage.removeWhere((id, _) => !touristIds.contains(id));
    _eventImage.removeWhere((id, _) => !eventIds.contains(id));
    _ratingCache.removeWhere((id, _) => !businessIds.contains(id));
    _priceCache.removeWhere((id, _) => !businessIds.contains(id));
  }

  // =========================
  // FILTERED GETTERS
  // =========================
  List<CategoryModel> get categories {
    if (isAll) return [];

    return allCategories
        .where((c) {
          // 🔹 BUSINESS
          if (selectedType == 'business') {
            return c.entityType == CategoryEntityType.business;
          }

          // 🔹 SERVICE (subtipo de business)
          if (selectedType == 'service') {
            return c.entityType == CategoryEntityType.business &&
                c.businessType == BusinessType.service;
          }

          // 🔹 TOURIST
          if (selectedType == 'tourist_place') {
            return c.entityType == CategoryEntityType.tourist_place;
          }

          // 🔹 EVENT
          if (selectedType == 'event') {
            return c.entityType == CategoryEntityType.event;
          }

          return false;
        })
        .where((c) => c.status == BasicStatus.active)
        .toList();
  }

  List<BusinessModel> get businesses {
    if (!isAll && !isBusiness && !isService) return [];

    var list = [...allBusinesses];

    list = list
        .where((b) => b.status == BusinessStatus.active && b.validated)
        .toList();

    /// 🔥 DIFERENCIA CLAVE
    if (isService) {
      list = list.where((b) => b.businessType == BusinessType.service).toList();
    }

    /// diferenciar business puro
    if (isBusiness) {
      list = list.where((b) => b.businessType != BusinessType.service).toList();
    }

    if (selectedCategoryId != null) {
      list = list.where((b) => b.categoryId == selectedCategoryId).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((b) => b.name.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  List<TouristPlaceModel> get touristPlaces {
    if (!isAll && !isTourist) return [];

    var list = [...allTouristPlaces];

    if (selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  List<EventModel> get events {
    if (!isAll && !isEvent) return [];

    var list = [...allEvents];

    if (selectedCategoryId != null) {
      list = list.where((e) => e.categoryId == selectedCategoryId).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  // =========================
  // MAP
  // =========================
  Future<void> _loadMarkers() async {
    markers = await MapMarkerService.buildMarkers(
      businesses: businesses,
      touristPlaces: touristPlaces,
      events: events,
    );
  }

  Future<void> _reloadMarkersForFilters() async {
    final requestId = ++_markerRequestId;

    markers = {};
    notifyListeners();

    final nextMarkers = await MapMarkerService.buildMarkers(
      businesses: businesses,
      touristPlaces: touristPlaces,
      events: events,
    );

    if (requestId != _markerRequestId) return;

    markers = nextMarkers;
    notifyListeners();
  }

  // =========================
  // HELPERS
  // =========================
  String? businessImage(int id) => _businessImage[id];
  String? touristImage(int id) => _touristImage[id];
  String? eventImage(int id) => _eventImage[id];

  String categoryLabel(int id) => _categoryName[id] ?? '';

  double? getRating(int id) => _ratingCache[id];
  double? getPrice(int id) => _priceCache[id];

  bool get isAll => selectedType == 'Todos';
  bool get isBusiness => selectedType == 'business';
  bool get isService => selectedType == 'service';
  bool get isTourist => selectedType == 'tourist_place';
  bool get isEvent => selectedType == 'event';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }
}
