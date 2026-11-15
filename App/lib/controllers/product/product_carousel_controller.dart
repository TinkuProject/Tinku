import 'package:flutter/material.dart';
import '../../../services/media_service.dart';

import '../../../models/product_model.dart';
import '../../../services/category_service.dart';
import '../../../helpers/media_helper.dart';
import '../../../core/enums.dart';

class ProductCarouselController extends ChangeNotifier {
  final MediaService mediaService;
  final CategoryService categoryService;

  ProductCarouselController({
    required this.mediaService,
    required this.categoryService,
  });

  // =========================
  // STATE
  // =========================
  final Map<int, String> categoryNames = {};
  final Map<int, List<String>> productImages = {};
  final Map<int, int> imageIndex = {};

  int currentPage = 0;
  bool loading = false;

  // =========================
  // LOAD
  // =========================
  Future<void> init(List<ProductModel> products) async {
    loading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadCategories(),
        _loadImages(products),
      ]);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await categoryService.getActive(
      entityType: CategoryEntityType.product,
    );

    categoryNames.clear();
    for (final c in cats) {
      categoryNames[c.id] = c.name;
    }
  }

  Future<void> loadCategoriesOnly() async {
    loading = true;
    notifyListeners();

    try {
      await _loadCategories();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadImages(List<ProductModel> products) async {
    productImages.clear();
    imageIndex.clear();

    for (final p in products) {
      productImages[p.id] = [];
      imageIndex[p.id] = 0;
    }

    final ids = products.map((p) => p.id).toList();
    if (ids.isEmpty) return;

    try {
      final mediaMap = await mediaService.getByEntities(
        entityIds: ids,
        entityType: MediaEntityType.product,
      );

      for (final p in products) {
        productImages[p.id] = MediaHelper.getImageUrls(mediaMap[p.id] ?? []);
      }
    } catch (_) {
      // Keep empty image lists initialized above.
    }
  }

  void setLoaded({
    required List<ProductModel> products,
    required Map<int, List<String>> mediaUrlsByProduct,
  }) {
    productImages
      ..clear()
      ..addAll({
        for (final product in products)
          product.id: mediaUrlsByProduct[product.id] ?? [],
      });
    imageIndex
      ..clear()
      ..addAll({
        for (final product in products) product.id: 0,
      });
    loading = false;
    notifyListeners();
  }

  // =========================
  // UI STATE
  // =========================
  void setCurrentPage(int index) {
    currentPage = index;
    notifyListeners();
  }

  void setImageIndex(int productId, int index) {
    imageIndex[productId] = index;
    notifyListeners();
  }
}
