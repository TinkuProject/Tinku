import 'dart:convert';
import '../../models/discount_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class DiscountService extends BaseService<DiscountModel> {
  DiscountService(AuthService authService)
      : super("discounts", authService);

  @override
  DiscountModel fromJson(Map<String, dynamic> json) {
    return DiscountModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(DiscountModel model) {
    return model.toJson();
  }

  Future<DiscountModel> createDiscount(Map<String, dynamic> data) async {
    final response = await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(data),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // GET BY BUSINESS (PUBLIC)
  // =========================
  Future<List<DiscountModel>> getByBusiness(int businessId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/business/$businessId'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    return data.map<DiscountModel>((e) => fromJson(e)).toList();
  }

  Future<Map<int, List<DiscountModel>>> getByBusinesses({
    required List<int> businessIds,
    bool activeOnly = false,
  }) async {
    if (businessIds.isEmpty) return {};

    final uniqueIds = businessIds.toSet().toList();
    final uri = Uri.parse('$baseUrl/$endpoint/businesses').replace(
      queryParameters: {
        'business_ids': uniqueIds.join(','),
        if (activeOnly) 'active': 'true',
      },
    );

    final response = await client.get(uri);

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
  // GET ACTIVE BY BUSINESS
  // =========================
  Future<List<DiscountModel>> getActive() async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/active'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<DiscountModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<DiscountModel>> getActiveByBusiness(int businessId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/business/$businessId/active'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<DiscountModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<DiscountModel>> getMine() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/my'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    return data
        .map<DiscountModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // UPDATE (PUT)
  // =========================
  Future<DiscountModel> updateDiscount(
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
  // DELETE (SOFT DELETE)
  // =========================
  Future<DiscountModel> softDelete(int id) async {
    final response = await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );

    final json = jsonDecode(response.body);

    return DiscountModel.fromJson(json);
  }
}
