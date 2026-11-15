import 'package:flutter/material.dart';

import '../../models/boost_model.dart';
import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/event_model.dart';
import '../../models/media_model.dart';
import '../../models/tourist_place_model.dart';
import '../../services/boost_service.dart';
import '../../services/media_service.dart';
import '../../services/business_service.dart';
import '../../services/event_service.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../services/system_config_service.dart';
import '../../services/tourist_place_service.dart';

class BoostController extends ChangeNotifier {
  final BoostService boostService;
  final MediaService mediaService;
  final BusinessService businessService;
  final EventService eventService;
  final ProductService productService;
  final ReviewService reviewService;
  final TouristPlaceService touristPlaceService;
  final SystemConfigService systemConfigService;

  BoostController({
    required this.boostService,
    required this.mediaService,
    required this.businessService,
    required this.eventService,
    required this.productService,
    required this.reviewService,
    required this.touristPlaceService,
    required this.systemConfigService,
  });

  // =========================
  // STATE
  // =========================
  List<BoostModel> activeBoosts = [];
  List<BoostModel> allBoosts = [];
  bool loading = false;
  List<BusinessModel> businesses = [];
  List<BusinessModel> promotableBusinesses = [];

  final Map<int, Map<String, dynamic>> _cache = {};
  double dailyCost = 0;

  Future<void> loadBoostCost() async {
    try {
      dailyCost = await systemConfigService.getBoostCreateCost();
    } catch (_) {
      if (dailyCost <= 0) {
        dailyCost = 20.0;
      }
    }
    notifyListeners();
  }

  // =========================
  // LOAD
  // =========================
  Future<void> loadMine() async {
    loading = true;
    _clearMineData();
    notifyListeners();

    try {
      if (dailyCost <= 0) {
        await loadBoostCost();
      }

      try {
        businesses = await businessService.getMine();
      } catch (_) {
        businesses = [];
      }

      try {
        final results = await Future.wait([
          boostService.getPromotableBusinesses(),
          boostService.getMine(),
        ]);

        promotableBusinesses = results[0] as List<BusinessModel>;
        allBoosts = results[1] as List<BoostModel>;
      } catch (_) {
        promotableBusinesses = [];
        allBoosts = [];
      }

      if (promotableBusinesses.isEmpty && businesses.isNotEmpty) {
        promotableBusinesses = businesses
            .where((b) => b.validated && b.status == BusinessStatus.active)
            .toList();
      }

      await _loadCardData(allBoosts);
    } catch (_) {
      // Preservar datos ya cargados
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadActive() async {
    loading = true;
    notifyListeners();

    try {
      activeBoosts = await boostService.getActive();

      _cache.clear();
      await _loadCardData(activeBoosts);
    } catch (_) {
      activeBoosts = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();

    try {
      if (dailyCost <= 0) {
        await loadBoostCost();
      }

      try {
        businesses = await businessService.getMine();
      } catch (_) {
        businesses = [];
      }

      try {
        final results = await Future.wait([
          boostService.getPromotableBusinesses(),
          boostService.getMine(),
        ]);

        promotableBusinesses = results[0] as List<BusinessModel>;
        allBoosts = results[1] as List<BoostModel>;
      } catch (_) {
        promotableBusinesses = [];
        allBoosts = [];
      }

      if (promotableBusinesses.isEmpty && businesses.isNotEmpty) {
        promotableBusinesses = businesses
            .where((b) => b.validated && b.status == BusinessStatus.active)
            .toList();
      }

      _cache.clear();
      await _loadCardData(allBoosts);
    } catch (_) {
      // Preservar datos ya cargados
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? getCardData(int boostId) {
    return _cache[boostId];
  }

  Future<void> _loadCardData(List<BoostModel> boosts) async {
    if (boosts.isEmpty) return;

    final businessIds = _idsFor(boosts, VisitEntity.business);
    final eventIds = _idsFor(boosts, VisitEntity.event);
    final placeIds = _idsFor(boosts, VisitEntity.tourist_place);

    final businessFuture = businessService.getByIds(businessIds);
    final eventFuture = eventService.getByIds(eventIds);
    final placeFuture = touristPlaceService.getByIds(placeIds);
    final businessMediaFuture = mediaService.getByEntities(
      entityIds: businessIds,
      entityType: MediaEntityType.business,
    );
    final businessProductsFuture = productService.getByBusinesses(
      businessIds: businessIds,
    );
    final businessReviewsFuture = reviewService.getByEntities(
      entityType: ReviewEntityType.business,
      entityIds: businessIds,
    );
    final eventMediaFuture = mediaService.getByEntities(
      entityIds: eventIds,
      entityType: MediaEntityType.event,
    );
    final placeMediaFuture = mediaService.getByEntities(
      entityIds: placeIds,
      entityType: MediaEntityType.tourist_place,
    );

    await Future.wait([
      businessFuture,
      eventFuture,
      placeFuture,
      businessMediaFuture,
      businessProductsFuture,
      businessReviewsFuture,
      eventMediaFuture,
      placeMediaFuture,
    ]);

    final businessesById = {
      for (final item in await businessFuture) item.id: item,
    };
    final eventsById = {
      for (final item in await eventFuture) item.id: item,
    };
    final placesById = {
      for (final item in await placeFuture) item.id: item,
    };

    final businessMedia = await businessMediaFuture;
    final businessProducts = await businessProductsFuture;
    final businessReviews = await businessReviewsFuture;
    final eventMedia = await eventMediaFuture;
    final placeMedia = await placeMediaFuture;

    for (final boost in boosts) {
      switch (boost.entityType) {
        case VisitEntity.business:
          _cache[boost.id] = _businessCardData(
            businessesById[boost.entityId],
            _firstImage(businessMedia[boost.entityId]),
            _averagePrice(businessProducts[boost.entityId]),
            _averageRating(businessReviews[boost.entityId]),
          );
          break;

        case VisitEntity.event:
          _cache[boost.id] = _eventCardData(
            eventsById[boost.entityId],
            _firstImage(eventMedia[boost.entityId]),
          );
          break;

        case VisitEntity.tourist_place:
          _cache[boost.id] = _placeCardData(
            placesById[boost.entityId],
            _firstImage(placeMedia[boost.entityId]),
          );
          break;
      }
    }
  }

  List<int> _idsFor(List<BoostModel> boosts, VisitEntity type) {
    return boosts
        .where((boost) => boost.entityType == type)
        .map((boost) => boost.entityId)
        .toSet()
        .toList();
  }

  String? _firstImage(List<MediaModel>? media) {
    if (media == null || media.isEmpty) return null;
    return media.first.url;
  }

  double? _averagePrice(List<dynamic>? products) {
    if (products == null || products.isEmpty) return null;

    final prices = products
        .map((product) => product.price)
        .whereType<double>()
        .where((price) => price > 0)
        .toList();

    if (prices.isEmpty) return null;

    return prices.reduce((sum, price) => sum + price) / prices.length;
  }

  double? _averageRating(List<dynamic>? reviews) {
    if (reviews == null || reviews.isEmpty) return null;

    final ratings = reviews
        .map((review) => review.rating)
        .whereType<double>()
        .where((rating) => rating > 0)
        .toList();

    if (ratings.isEmpty) return null;

    return ratings.reduce((sum, rating) => sum + rating) / ratings.length;
  }

  Map<String, dynamic> _businessCardData(
    BusinessModel? business,
    String? imageUrl,
    double? price,
    double? rating,
  ) {
    return {
      'title': business?.name ?? 'Negocio',
      'subtitle': business?.description ?? '',
      'image': imageUrl,
      'icon': Icons.store,
      'price': price,
      'rating': rating,
    };
  }

  Map<String, dynamic> _eventCardData(
    EventModel? event,
    String? imageUrl,
  ) {
    return {
      'title': event?.name ?? 'Evento',
      'subtitle': event?.description ?? '',
      'image': imageUrl,
      'icon': Icons.event,
    };
  }

  Map<String, dynamic> _placeCardData(
    TouristPlaceModel? place,
    String? imageUrl,
  ) {
    return {
      'title': place?.name ?? 'Lugar',
      'subtitle': place?.description ?? '',
      'image': imageUrl,
      'icon': Icons.place,
    };
  }

  Map<int, String> get businessSelectorItems {
    final source = businesses.isNotEmpty ? businesses : promotableBusinesses;

    return {
      for (final b in source) b.id: b.name,
    };
  }

  Set<int> get disabledBusinessSelectorIds {
    final promotableIds = promotableBusinesses.map((b) => b.id).toSet();
    final source = businesses.isNotEmpty ? businesses : promotableBusinesses;

    return source
        .where((b) => !promotableIds.contains(b.id))
        .map((b) => b.id)
        .toSet();
  }

  bool get hasBusinesses =>
      businesses.isNotEmpty || promotableBusinesses.isNotEmpty;

  bool get hasPromotableBusinesses => promotableBusinesses.isNotEmpty;

  int getDays(BoostModel boost) {
    return boost.endDate.difference(boost.startDate).inDays + 1;
  }

  double getEstimatedAmount(BoostModel boost) {
    final days = getDays(boost);
    return days * dailyCost;
  }

  int getRemainingDays(BoostModel boost) {
    final now = DateTime.now();
    if (boost.endDate.isBefore(now)) return 0;
    return boost.endDate.difference(now).inDays;
  }

  void _clearMineData() {
    allBoosts = [];
    businesses = [];
    promotableBusinesses = [];
    _cache.clear();
  }

  void resetMine() {
    _clearMineData();
    loading = false;
    notifyListeners();
  }
}
