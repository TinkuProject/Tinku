import 'dart:convert';
import '../../models/category_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class CategoryService extends BaseService<CategoryModel> {
  CategoryService(AuthService authService)
      : super("categories", authService);

  @override
  CategoryModel fromJson(Map<String, dynamic> json) {
    return CategoryModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CategoryModel model) {
    return model.toJson();
  }

  // =========================
  // GET ACTIVE BY TYPE (PUBLIC)
  // =========================
  Future<List<CategoryModel>> getActive({
    required CategoryEntityType entityType,
    BusinessType? businessType,
  }) async {
    final query = {
      'entity_type': categoryEntityTypeToString(entityType),
      if (businessType != null)
        'business_type': businessTypeToString(businessType),
    };

    final uri = Uri.parse('$baseUrl/$endpoint/active')
        .replace(queryParameters: query);

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<CategoryModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET NAME BY ID
  // =========================
  Future<String> getCategoryName(int id) async {
    final cat = await getById(id);
    return cat?.name ?? 'Categoría';
  }

  // =========================
  // GET BY IDS (BATCH)
  // =========================
  Future<List<CategoryModel>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/$endpoint/batch').replace(
      queryParameters: {
        'ids': ids.join(','),
      },
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<CategoryModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
    )
        .toList();
  }

  // =========================
  // GET NAMES BY IDS (MAP)
  // =========================
  Future<Map<int, String>> getNamesByIds(List<int> ids) async {
    final categories = await getByIds(ids);

    return {
      for (final c in categories) c.id: c.name,
    };
  }
}