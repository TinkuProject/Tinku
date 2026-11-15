import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/product_model.dart';
import '../../services/business_service.dart';
import '../../services/media_service.dart';
import '../../services/product_service.dart';

class ProductController extends ChangeNotifier {
  ProductController(
    this._productService,
    this._businessService,
    this._mediaService,
  );

  final ProductService _productService;
  final BusinessService _businessService;
  final MediaService _mediaService;

  // =========================
  // STATE
  // =========================
  List<ProductModel> products = [];
  List<BusinessModel> businesses = [];
  final Map<int, String?> _imageCache = {};

  double? averagePrice;
  bool loading = false;

  // Filtros de UI que sí conviene centralizar aquí
  int _filterOrder = 0;
  int _selectedBusiness = 0;

  int get filterOrder => _filterOrder;
  int get selectedBusiness => _selectedBusiness;

  void setFilterOrder(int value) {
    if (_filterOrder == value) return;
    _filterOrder = value;
    notifyListeners();
  }

  void setSelectedBusiness(int value) {
    if (_selectedBusiness == value) return;
    _selectedBusiness = value;
    notifyListeners();
  }

  void resetFilters() {
    _filterOrder = 0;
    _selectedBusiness = 0;
    notifyListeners();
  }

  String? imageFor(int productId) => _imageCache[productId];

  // =========================
  // LOAD ALL MY PRODUCTS
  // =========================
  Future<void> loadMine() async {
    loading = true;
    notifyListeners();

    try {
      final loadedProducts = await _productService.getMine();
      final loadedBusinesses = await _businessService.getMine();
      final loadedImages = await _loadMedia(loadedProducts);
      products = loadedProducts;
      businesses = loadedBusinesses;
      _imageCache
        ..clear()
        ..addAll(loadedImages);
      _recalculateAverage();
    } catch (_) {
      // Conserva los últimos datos válidos ante errores temporales.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<int, String?>> _loadMedia(List<ProductModel> items) async {
    final result = <int, String?>{};
    final ids = items.map((p) => p.id).toList();
    if (ids.isEmpty) return result;

    final mediaMap = await _mediaService.getByEntities(
      entityIds: ids,
      entityType: MediaEntityType.product,
    );

    for (final p in items) {
      final medias = mediaMap[p.id] ?? [];
      result[p.id] = medias.isNotEmpty ? medias.first.url : null;
    }
    return result;
  }

  // =========================
  // LOAD BY BUSINESS
  // =========================
  Future<void> loadByBusiness(int businessId) async {
    if (businessId == 0) {
      await loadMine();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final loadedProducts = await _productService.getByBusiness(businessId);
      final loadedImages = await _loadMedia(loadedProducts);
      products = loadedProducts;
      _imageCache
        ..clear()
        ..addAll(loadedImages);
      _recalculateAverage();

      if (businesses.isEmpty) {
        try {
          businesses = await _businessService.getMine();
        } catch (_) {}
      }
    } catch (_) {
      // Conserva el listado previo si el filtro no puede actualizarse.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setBusinessProducts({
    required int businessId,
    required List<ProductModel> items,
    required Map<int, List<String>> mediaUrlsByProduct,
  }) {
    products = items;
    businesses = [];
    _selectedBusiness = businessId;
    _imageCache
      ..clear()
      ..addAll({
        for (final product in items)
          product.id: (mediaUrlsByProduct[product.id] ?? []).isNotEmpty
              ? mediaUrlsByProduct[product.id]!.first
              : null,
      });
    _recalculateAverage();
    loading = false;
    notifyListeners();
  }

  // =========================
  // DELETE
  // =========================
  Future<void> softDeleteProduct(ProductModel product) async {
    try {
      await _productService.softDelete(product.id);
      await refresh();
    } catch (_) {
      throw Exception('Error al eliminar el producto');
    }
  }

  // =========================
  // REFRESH
  // =========================
  Future<void> refresh() async {
    await loadMine();
  }

  // =========================
  // HELPERS
  // =========================
  void _recalculateAverage() {
    if (products.isEmpty) {
      averagePrice = null;
      return;
    }

    final total = products.fold<double>(
      0,
      (acc, p) => acc + ((p.price ?? 0).toDouble()),
    );

    averagePrice = total / products.length;
  }

  List<ProductModel> get filteredProducts {
    final list = products.where((p) {
      if (_selectedBusiness != 0 && p.businessId != _selectedBusiness) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (_filterOrder == 0) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return list;
  }

  String businessNameFor(int businessId) {
    for (final b in businesses) {
      if (b.id == businessId) return b.name;
    }
    return 'Sin negocio';
  }

  bool showingTinku(ProductModel product) {
    return (product.price == null || product.price == 0) &&
        (product.tinkuPrice != null && product.tinkuPrice! > 0);
  }

  // =========================
  // SELECTOR HELPERS
  // =========================
  Map<int, String> get businessSelectorItems {
    return {
      0: "Todos mis productos",
      for (final b in businesses) b.id: b.name,
    };
  }

  Set<int> get disabledBusinessSelectorIds {
    return businesses
        .where((b) => !b.validated || b.status != BusinessStatus.active)
        .map((b) => b.id)
        .toSet();
  }

  bool get hasBusinesses => businesses.isNotEmpty;
  bool get hasData => products.isNotEmpty;

  // =========================
  // RESET
  // =========================
  void reset() {
    products.clear();
    businesses.clear();
    averagePrice = null;
    _imageCache.clear();
    resetFilters();
    notifyListeners();
  }
}
