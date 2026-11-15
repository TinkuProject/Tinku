import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/business_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/product_model.dart';
import '../../services/business_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/product_service.dart';

class MarketplaceController extends ChangeNotifier {
  MarketplaceController(
    this._marketplaceService,
    this._productService,
    this._businessService,
  );

  final MarketplaceService _marketplaceService;
  final ProductService _productService;
  final BusinessService _businessService;

  bool loading = false;
  bool loadingMore = false;
  bool hasMorePublications = false;
  bool loadingMoreMine = false;
  bool hasMoreMine = false;
  String? mineMoreError;
  bool saving = false;
  String? error;
  String search = '';
  String availability = 'all';
  String? volume;
  int? minTinkus;
  int? maxTinkus;
  String sort = 'newest';
  bool get hasPublicFilters =>
      availability != 'all' ||
      volume != null ||
      minTinkus != null ||
      maxTinkus != null ||
      sort != 'newest';
  int selectedBusinessId = 0;
  Timer? _searchDebounce;
  int _publicRequestVersion = 0;
  int _mineRequestVersion = 0;
  int _mineOffset = 0;
  bool _disposed = false;

  List<MarketplacePublicationModel> publications = [];
  List<MarketplacePublicationModel> mine = [];
  List<ProductModel> myProducts = [];
  List<BusinessModel> businesses = [];

  List<MarketplacePublicationModel> get visibleMine {
    if (selectedBusinessId == 0) return List.of(mine);
    return mine.where((item) => item.businessId == selectedBusinessId).toList();
  }

  Map<int, String> get businessSelectorItems => {
        0: 'Todos mis negocios',
        for (final business in businesses) business.id: business.name,
      };

  Future<void> loadPublic() async {
    final requestVersion = ++_publicRequestVersion;

    loading = true;
    error = null;
    notifyListeners();

    try {
      final loaded = await _marketplaceService.getPublications(
        q: search,
        availability: availability,
        volume: volume,
        minTinkus: minTinkus,
        maxTinkus: maxTinkus,
        sort: sort,
      );
      if (requestVersion != _publicRequestVersion) return;
      publications = loaded;
      hasMorePublications = loaded.length == 20;
    } catch (_) {
      if (requestVersion != _publicRequestVersion) return;
      error = 'No se pudo cargar el marketplace';
    } finally {
      if (requestVersion == _publicRequestVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMorePublic() async {
    if (loading || loadingMore || !hasMorePublications) return;
    final requestVersion = _publicRequestVersion;
    loadingMore = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await _marketplaceService.getPublications(
        q: search,
        availability: availability,
        volume: volume,
        minTinkus: minTinkus,
        maxTinkus: maxTinkus,
        sort: sort,
        offset: publications.length,
      );
      if (requestVersion != _publicRequestVersion) return;
      final ids = publications.map((item) => item.id).toSet();
      publications.addAll(loaded.where((item) => ids.add(item.id)));
      hasMorePublications = loaded.length == 20;
    } catch (_) {
      if (requestVersion != _publicRequestVersion) return;
      hasMorePublications = true;
      error = 'No se pudieron cargar más productos';
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMine() async {
    final version = ++_mineRequestVersion;
    loading = true;
    loadingMoreMine = false;
    error = null;
    mineMoreError = null;
    notifyListeners();

    try {
      final loaded = await Future.wait([
        _marketplaceService.getMine(),
        _productService.getMine(),
        _businessService.getMine(),
      ]);
      if (_disposed || version != _mineRequestVersion) return;
      mine = loaded[0] as List<MarketplacePublicationModel>;
      myProducts = loaded[1] as List<ProductModel>;
      businesses = loaded[2] as List<BusinessModel>;
      _mineOffset = mine.length;
      hasMoreMine = mine.length == 20;
    } catch (_) {
      if (_disposed || version != _mineRequestVersion) return;
      error = 'No se pudieron cargar tus publicaciones';
    } finally {
      if (!_disposed && version == _mineRequestVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreMine() async {
    if (_disposed || loading || loadingMoreMine || !hasMoreMine) return;
    final version = _mineRequestVersion;
    loadingMoreMine = true;
    mineMoreError = null;
    notifyListeners();

    try {
      final page = await _marketplaceService.getMine(offset: _mineOffset);
      if (_disposed || version != _mineRequestVersion) return;
      _mineOffset += page.length;
      hasMoreMine = page.length == 20;
      final ids = mine.map((item) => item.id).toSet();
      mine.addAll(page.where((item) => ids.add(item.id)));
    } catch (_) {
      if (_disposed || version != _mineRequestVersion) return;
      mineMoreError = 'No se pudieron cargar más publicaciones';
    } finally {
      if (!_disposed && version == _mineRequestVersion) {
        loadingMoreMine = false;
        notifyListeners();
      }
    }
  }

  void setSearch(String value) {
    search = value;
    _publicRequestVersion++;
    _marketplaceService.cancelPublicationsRequest();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      loadPublic,
    );
    notifyListeners();
  }

  Future<void> setPublicFilters({
    required String availability,
    required String? volume,
    required int? minTinkus,
    required int? maxTinkus,
    required String sort,
  }) {
    this.availability = availability;
    this.volume = volume;
    this.minTinkus = minTinkus;
    this.maxTinkus = maxTinkus;
    this.sort = sort;
    _searchDebounce?.cancel();
    _marketplaceService.cancelPublicationsRequest();
    return loadPublic();
  }

  void setSelectedBusiness(int value) {
    selectedBusinessId = value;
    notifyListeners();
  }

  Future<void> refreshPublic() {
    _searchDebounce?.cancel();
    return loadPublic();
  }

  Future<void> refreshMine() => loadMine();

  Future<MarketplacePublicationEstimateModel> estimatePublication({
    required ProductModel product,
    required int stock,
    int? unitTinkuPrice,
  }) {
    return _marketplaceService.estimatePublication(
      productId: product.id,
      publishedStock: stock,
      unitTinkuPrice: unitTinkuPrice,
    );
  }

  Future<void> publishProduct(
    ProductModel product,
    int stock, {
    int? unitTinkuPrice,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _marketplaceService.createPublication(
        productId: product.id,
        publishedStock: stock,
        unitTinkuPrice: unitTinkuPrice,
      );
      await loadMine();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> updateStock(
    MarketplacePublicationModel publication,
    int stock, {
    int? unitTinkuPrice,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _marketplaceService.updatePublicationStock(
        publicationId: publication.id,
        publishedStock: stock,
        unitTinkuPrice: unitTinkuPrice,
      );
      await loadMine();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(
    MarketplacePublicationModel publication,
    String status,
  ) async {
    saving = true;
    notifyListeners();

    try {
      await _marketplaceService.updatePublicationStatus(
        publicationId: publication.id,
        status: status,
      );
      await loadMine();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> registerView(int businessId) {
    return _marketplaceService.registerBusinessView(businessId);
  }

  @override
  void dispose() {
    _disposed = true;
    _publicRequestVersion++;
    _mineRequestVersion++;
    _searchDebounce?.cancel();
    _marketplaceService.cancelPublicationsRequest();
    super.dispose();
  }
}
