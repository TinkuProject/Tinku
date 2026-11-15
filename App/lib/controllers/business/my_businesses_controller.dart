import 'package:flutter/material.dart';
import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/media_service.dart';
import '../../services/review_service.dart';
import '../../services/marketplace_service.dart';

class MyBusinessesController extends ChangeNotifier {
  MyBusinessesController(
    this._businessSvc,
    this._categorySvc,
    this._mediaSvc,
    this._reviewSvc,
    this._marketplaceSvc,
  );

  final BusinessService _businessSvc;
  final CategoryService _categorySvc;
  final MediaService _mediaSvc;
  final ReviewService _reviewSvc;
  final MarketplaceService _marketplaceSvc;

  bool loading = false;
  String? error;
  List<BusinessModel> businesses = [];

  final Map<int, String> _categoryNameCache = {};
  final Map<int, List<String>> _mediaCache = {}; // id negocio → urls
  final Map<int, double> _ratingCache = {};
  final Map<int, int> _viewCountCache = {};

  String categoryLabel(int categoryId) =>
      _categoryNameCache[categoryId] ?? 'Categoría';

  List<String> mediaUrlsFor(int businessId) => _mediaCache[businessId] ?? [];

  double? getRating(int businessId) => _ratingCache[businessId];

  int getViews(int businessId) => _viewCountCache[businessId] ?? 0;

  Future<void> load() async {
    loading = true;
    error = null;
    _clearData();
    notifyListeners();

    try {
      businesses = await _businessSvc.getMine();
      if (businesses.isEmpty) return;

      final categoryIds = businesses.map((b) => b.categoryId).toSet().toList();
      final businessIds = businesses.map((b) => b.id).toList();
      await Future.wait([
        _loadCategories(categoryIds),
        _loadMedia(businessIds),
        _loadRatings(businessIds),
        _loadViews(businessIds),
      ]);
    } catch (_) {
      error = 'No se pudieron cargar tus negocios';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCategories(List<int> ids) async {
    try {
      _categoryNameCache.addAll(await _categorySvc.getNamesByIds(ids));
    } catch (_) {}
  }

  Future<void> _loadMedia(List<int> ids) async {
    try {
      final mediaMap = await _mediaSvc.getByEntities(
        entityIds: ids,
        entityType: MediaEntityType.business,
      );
      _mediaCache.addAll(mediaMap.map(
        (key, value) => MapEntry(key, value.map((media) => media.url).toList()),
      ));
    } catch (_) {}
  }

  Future<void> _loadRatings(List<int> ids) async {
    try {
      final reviewMap = await _reviewSvc.getByEntities(
        entityType: ReviewEntityType.business,
        entityIds: ids,
      );
      for (final entry in reviewMap.entries) {
        final reviews = entry.value;
        if (reviews.isEmpty) continue;
        final average =
            reviews.map((review) => review.rating).reduce((a, b) => a + b) /
                reviews.length;
        _ratingCache[entry.key] = double.parse(average.toStringAsFixed(1));
      }
    } catch (_) {}
  }

  Future<void> _loadViews(List<int> ids) async {
    try {
      _viewCountCache.addAll(
        await _marketplaceSvc.getBusinessViewStatsBatch(ids),
      );
    } catch (_) {}
  }

  bool canManageBusiness(BusinessModel e) {
    return e.status == BusinessStatus.pending ||
        e.status == BusinessStatus.active;
  }

  void _clearData() {
    businesses = [];
    _categoryNameCache.clear();
    _mediaCache.clear();
    _ratingCache.clear();
    _viewCountCache.clear();
  }

  void reset() {
    _clearData();
    error = null;
    loading = false;
    notifyListeners();
  }

  Future<bool> softDeleteBusiness(BusinessModel b) async {
    try {
      final updated = await _businessSvc.softDelete(b.id);

      final index = businesses.indexWhere((x) => x.id == updated.id);
      if (index != -1) {
        businesses[index] = updated;
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  ({String label, Color color, IconData icon}) statusMeta(BusinessModel b) {
    switch (b.status) {
      case BusinessStatus.active:
        return (
          label: 'Activo',
          color: Colors.green,
          icon: Icons.check_circle,
        );

      case BusinessStatus.pending:
        return (
          label: 'Pendiente',
          color: Colors.orange,
          icon: Icons.hourglass_empty,
        );

      case BusinessStatus.suspended:
        return (
          label: 'Suspendido',
          color: Colors.red,
          icon: Icons.block,
        );

      case BusinessStatus.inactive:
        return (
          label: 'Inactivo',
          color: Colors.grey,
          icon: Icons.pause_circle,
        );
    }
  }
}
