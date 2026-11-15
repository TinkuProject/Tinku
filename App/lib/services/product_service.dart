import 'dart:convert';
import '../../models/product_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class ProductService extends BaseService<ProductModel> {
  ProductService(AuthService authService) : super("products", authService);

  @override
  ProductModel fromJson(Map<String, dynamic> json) {
    return ProductModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ProductModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY BUSINESS (PUBLIC)
  // =========================
  Future<List<ProductModel>> getByBusiness(int businessId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/business/$businessId'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ProductModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET MINE (MANAGEMENT)
  // =========================
  Future<List<ProductModel>> getMine() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/my'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ProductModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY BUSINESSES (BATCH)
  // =========================
  Future<Map<int, List<ProductModel>>> getByBusinesses({
    required List<int> businessIds,
  }) async {
    if (businessIds.isEmpty) return {};

    final uri = Uri.parse('$baseUrl/$endpoint/businesses').replace(
      queryParameters: {
        'business_ids': businessIds.join(','), // "1,2,3"
      },
    );

    final response = await client.get(uri, headers: await headers());

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data.map((key, value) {
      return MapEntry(
        int.parse(key),
        (value as List)
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    });
  }

  // =========================
  // UPDATE
  // =========================
  Future<ProductModel> updateProduct(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final response = await request(
      () async => client.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // DELETE
  // =========================
  Future<ProductModel> softDelete(int id) async {
    final response = await request(
      () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ProductModel.fromJson(json);
  }

  // =========================
  // ADMIN
  // =========================
  Future<List<ProductModel>> getAllAdmin() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/admin/all'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ProductModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ProductModel>> getByBusinessAdmin(int businessId) async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/admin/business/$businessId'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ProductModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
