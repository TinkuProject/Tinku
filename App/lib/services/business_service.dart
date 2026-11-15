import 'dart:convert';
import '../../core/enums.dart';
import '../../models/business_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class BusinessService extends BaseService<BusinessModel> {
  BusinessService(AuthService authService) : super("businesses", authService);

  @override
  BusinessModel fromJson(Map<String, dynamic> json) {
    return BusinessModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BusinessModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY CATEGORY (PUBLIC)
  // =========================
  Future<List<BusinessModel>> getByCategory(int categoryId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/category/$categoryId'),
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
        .map<BusinessModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY IDS (BATCH)
  // =========================
  Future<List<BusinessModel>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/$endpoint/batch').replace(
      queryParameters: {
        'ids': ids.join(','),
      },
    );

    final response = await client.get(uri, headers: await headers());

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET MINE (PROTECTED)
  // =========================
  Future<List<BusinessModel>> getMine() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/mine'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET CLAIMABLE (PARTNER)
  // =========================
  Future<List<BusinessModel>> getClaimable() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/claimable'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY STATUS (ADMIN)
  // =========================
  Future<List<BusinessModel>> getByStatus(BusinessStatus status) async {
    final uri = Uri.parse('$baseUrl/$endpoint/status').replace(
      queryParameters: {
        'status': businessStatusToString(status),
      },
    );

    final response = await request(
      () async => client.get(
        uri,
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET DETAIL (PUBLIC AGGREGATE)
  // =========================
  Future<Map<String, dynamic>> getDetail(int id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id/detail'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data;
  }

  // =========================
  // VALIDATE (ADMIN)
  // =========================
  Future<void> validateBusiness(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/validate'),
        headers: await headers(),
        body: jsonEncode({}),
      ),
    );
  }

  // =========================
  // REJECT (ADMIN)
  // =========================
  Future<void> rejectBusiness(int id, {required String message}) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/reject'),
        headers: await headers(),
        body: jsonEncode({
          'message': message.trim(),
        }),
      ),
    );
  }

  // =========================
  // SOFT DELETE
  // =========================
  Future<BusinessModel> softDelete(int id) async {
    final response = await request(
      () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BusinessModel.fromJson(json);
  }
}
