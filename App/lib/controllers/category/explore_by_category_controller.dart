import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/event_model.dart';
import '../../models/tourist_place_model.dart';

import '../../services/business_service.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';
import '../../services/tourist_place_service.dart';
import '../../services/review_service.dart';
import '../../services/product_service.dart';
import '../../services/explore_feed_service.dart';

class BusinessExtras {
  final double? ratingAvg;
  final double? priceAvg;
  const BusinessExtras({this.ratingAvg, this.priceAvg});
}

class ExploreByCategoryController extends ChangeNotifier {
  ExploreByCategoryController(
      this._businessSvc,
      this._eventSvc,
      this._placeSvc,
      this._reviewSvc,
      this._productSvc,
      this._mediaService,
      this._exploreFeedService,
      );

  final BusinessService _businessSvc;
  final EventService _eventSvc;
  final TouristPlaceService _placeSvc;
  final ReviewService _reviewSvc;
  final ProductService _productSvc;
  final MediaService _mediaService;
  final ExploreFeedService _exploreFeedService;

  final Map<int, String?> eventImages = {};
  final Map<int, String?> touristPlaceImages = {};

  // Input
  late int categoryId;
  late String categoryType;
  late String categoryName;

  bool loading = false;

  // Data
  final List<dynamic> items = [];
  final Map<int, BusinessExtras> businessExtras = {};

  // Map
  Set<Marker> markers = {};
  LatLng? initialPosition;

  Future<void> init({
    required int id,
    required String type,
    required String name,
  }) async {
    categoryId = id;
    categoryType = type;
    categoryName = name;
    await load();
  }

  Future<void> load() async {
    loading = true;
    items.clear();
    markers = {};
    initialPosition = null;
    businessExtras.clear();
    notifyListeners();

    try {
      await _loadFromFeed();
    } catch (_) {
      await _loadLegacy();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFeed() async {
    final feed = await _exploreFeedService.getFeed();

    switch (categoryType) {
      case 'tourist_place':
        items.addAll(
          feed.touristPlaces.where((p) => p.categoryId == categoryId),
        );
        touristPlaceImages
          ..clear()
          ..addAll(feed.touristImages);
        break;

      case 'event':
        items.addAll(
          feed.events.where((e) => e.categoryId == categoryId),
        );
        eventImages
          ..clear()
          ..addAll(feed.eventImages);
        break;

      case 'business':
      case 'service':
        final targetType = businessTypeFromString(categoryType);
        final businesses = feed.businesses.where(
          (b) => b.categoryId == categoryId && b.businessType == targetType,
        );
        items.addAll(businesses);

        for (final b in items.whereType<BusinessModel>()) {
          businessExtras[b.id] = BusinessExtras(
            ratingAvg: feed.businessRatings[b.id],
            priceAvg: feed.businessPrices[b.id],
          );
        }
        break;

      default:
        items.clear();
    }

    _buildMarkersAndInitial();
  }

  Future<void> _loadLegacy() async {
    switch (categoryType) {
      case 'tourist_place':
        items.addAll(await _placeSvc.getByCategory(categoryId));
        break;

      case 'event':
        items.addAll(await _eventSvc.getByCategory(categoryId));
        break;

      case 'business':
      case 'service':
        final all = await _businessSvc.getByCategory(categoryId);
        items.addAll(
          all.where(
            (b) => b.businessType == businessTypeFromString(categoryType),
          ),
        );
        break;

      default:
        items.clear();
    }

    _buildMarkersAndInitial();

    await Future.wait([
      _loadImagesBatch(),
      if (categoryType == 'business' || categoryType == 'service')
        _prefetchBusinessExtrasBatch(),
    ]);
  }

  // =========================
  // MEDIA (BATCH)
  // =========================
  Future<void> _loadImagesBatch() async {
    eventImages.clear();
    touristPlaceImages.clear();

    final eventIds = items.whereType<EventModel>().map((e) => e.id).toList();
    final placeIds =
    items.whereType<TouristPlaceModel>().map((p) => p.id).toList();

    if (eventIds.isNotEmpty) {
      final eventMedia = await _mediaService.getByEntities(
        entityIds: eventIds,
        entityType: MediaEntityType.event,
      );

      for (final entry in eventMedia.entries) {
        eventImages[entry.key] =
        entry.value.isNotEmpty ? entry.value.first.url : null;
      }
    }

    if (placeIds.isNotEmpty) {
      final placeMedia = await _mediaService.getByEntities(
        entityIds: placeIds,
        entityType: MediaEntityType.tourist_place,
      );

      for (final entry in placeMedia.entries) {
        touristPlaceImages[entry.key] =
        entry.value.isNotEmpty ? entry.value.first.url : null;
      }
    }
  }

  // =========================
  // MARKERS
  // =========================
  void _buildMarkersAndInitial() {
    for (final item in items) {
      final lat = item.latitude!;
      final lng = item.longitude!;

      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
      InfoWindow info = InfoWindow(title: item.name);

      if (item is EventModel) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          item.status == EventStatus.active
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueAzure,
        );

        info = InfoWindow(
          title: item.name,
          snippet: item.status == EventStatus.active
              ? 'Ver evento'
              : 'Evento finalizado',
        );
      }

      markers.add(
        Marker(
          markerId: MarkerId("${item.runtimeType}-${item.id}"),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: info,
        ),
      );

      initialPosition ??= LatLng(lat, lng);
    }
  }

  // =========================
  // EXTRAS (BATCH 🚀)
  // =========================
  Future<void> _prefetchBusinessExtrasBatch() async {
    final businesses = items.whereType<BusinessModel>().toList();
    if (businesses.isEmpty) return;

    final ids = businesses.map((b) => b.id).toList();

    final results = await Future.wait([
      _reviewSvc.getByEntities(
        entityType: ReviewEntityType.business,
        entityIds: ids,
      ),
      _productSvc.getByBusinesses(
        businessIds: ids,
      ),
    ]);

    final reviewsMap = results[0] as Map<int, List<dynamic>>;
    final productsMap = results[1] as Map<int, List<dynamic>>;

    for (final b in businesses) {
      final reviews = reviewsMap[b.id] ?? [];
      final products = productsMap[b.id] ?? [];

      double? rating;
      if (reviews.isNotEmpty) {
        final total =
        reviews.fold<double>(0, (acc, r) => acc + r.rating);
        rating = total / reviews.length;
      }

      double? price;
      if (products.isNotEmpty) {
        final total =
        products.fold<double>(0, (acc, p) => acc + (p.price ?? 0));
        price = total / products.length;
      }

      businessExtras[b.id] =
          BusinessExtras(ratingAvg: rating, priceAvg: price);
    }
  }

  BusinessExtras? extrasFor(int businessId) =>
      businessExtras[businessId];
}
