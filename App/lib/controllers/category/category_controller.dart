import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../core/enums.dart';

class CategoryController extends ChangeNotifier {
  final CategoryService _service;

  CategoryController(this._service);

  List<CategoryModel> categories = [];
  bool loading = false;

  Future<void> load(CategoryEntityType type) async {
    loading = true;
    notifyListeners();

    try {
      categories = await _service.getActive(entityType: type);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void reset() {
    categories.clear();
    notifyListeners();
  }
}