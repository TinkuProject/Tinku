import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/media_target.dart';
import '../../models/product_model.dart';
import '../../services/category_service.dart';
import '../../services/media_service.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../shared/media/media_controller.dart';

class ProductFormController extends ChangeNotifier {
  ProductFormController({
    required ProductService productService,
    required CategoryService categoryService,
    required StorageService storageService,
    required MediaService mediaService,
    required this.businessId,
    this.product,
  })  : _productService = productService,
        _categoryService = categoryService,
        media = MediaController(storageService, mediaService) {
    media.addListener(_onMediaChanged);
  }

  final ProductService _productService;
  final CategoryService _categoryService;

  final int businessId;
  final ProductModel? product;

  final MediaController media;

  // =========================
  // STATE
  // =========================
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController tinkuPriceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();

  String categoryId = '';
  String volumeTier = 'small';
  bool loading = false;

  Map<String, String> categories = {};

  bool get editing => product != null;
  List<dynamic> get images => media.items;

  // =========================
  // LISTENER
  // =========================
  void _onMediaChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  bool _disposed = false;

  // =========================
  // INIT
  // =========================
  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      await _loadCategories();

      if (editing) {
        await _loadExistingProduct();
      }
    } catch (_) {
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadExistingProduct() async {
    final p = product!;

    nameCtrl.text = p.name;
    descCtrl.text = p.description ?? '';
    priceCtrl.text = p.price != null && p.price! > 0 ? p.price.toString() : '';
    tinkuPriceCtrl.text =
    p.tinkuPrice != null && p.tinkuPrice! > 0 ? p.tinkuPrice.toString() : '';
    stockCtrl.text = p.stock != null && p.stock! > 0 ? p.stock.toString() : '';
    volumeTier = p.volumeTier;
    categoryId = p.categoryId.toString();

    await media.load(
      target: EntityMediaTarget(
        entityId: p.id,
        entityType: MediaEntityType.product,
      ),
    );

    notifyListeners();
  }

  Future<void> _loadCategories() async {
    final list = await _categoryService.getActive(
      entityType: CategoryEntityType.product,
    );

    categories = {
      for (final c in list) c.id.toString(): c.name,
    };
  }

  // =========================
  // ACTIONS
  // =========================
  void setCategory(String? value) {
    categoryId = value ?? '';
    notifyListeners();
  }

  void setVolumeTier(String? value) {
    volumeTier = value ?? 'small';
    notifyListeners();
  }

  double? _parseOptionalDouble(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;

    return parsed;
  }

  int? _parseOptionalInt(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return null;

    return parsed;
  }

  // =========================
  // SAVE
  // =========================
  Future<ProductModel> save() async {
    loading = true;
    notifyListeners();

    try {
      final model = ProductModel(
        id: editing ? product!.id : 0,
        businessId: businessId,
        categoryId: int.parse(categoryId),
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        price: _parseOptionalDouble(priceCtrl.text),
        tinkuPrice: _parseOptionalDouble(tinkuPriceCtrl.text),
        stock: _parseOptionalInt(stockCtrl.text),
        volumeTier: volumeTier,
        status: editing ? product!.status : ProductStatus.active,
        createdAt: editing ? product!.createdAt : DateTime.now(),
        updatedAt: editing ? DateTime.now() : null,
      );

      final saved = editing
          ? await _productService.update(product!.id, model.toJson())
          : await _productService.create(model);

      await media.saveDirect(
        target: EntityMediaTarget(
          entityId: saved.id,
          entityType: MediaEntityType.product,
        ),
      );

      return saved;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // RESET
  // =========================
  void reset() {
    _disposed = true;

    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    tinkuPriceCtrl.dispose();
    stockCtrl.dispose();

    media.removeListener(_onMediaChanged);
    media.reset();

    super.dispose();
  }
}
