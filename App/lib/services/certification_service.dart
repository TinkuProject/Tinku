import 'dart:convert';
import '../../models/certification_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class CertificationService extends BaseService<CertificationModel> {
  CertificationService(AuthService authService)
      : super("certifications", authService);

  @override
  CertificationModel fromJson(Map<String, dynamic> json) {
    return CertificationModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CertificationModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY BUSINESS (PUBLIC)
  // =========================
  Future<List<CertificationModel>> getByBusiness(int businessId) async {
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
        .map<CertificationModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY BUSINESSES (BATCH)
  // =========================
  Future<Map<int, List<CertificationModel>>> getByBusinesses({
    required List<int> businessIds,
  }) async {
    if (businessIds.isEmpty) return {};

    final uri = Uri.parse('$baseUrl/$endpoint/businesses').replace(
      queryParameters: {
        'business_ids': businessIds.join(','),
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
  Future<CertificationModel> patchCertification(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final response = await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // ACTIVATE / DEACTIVATE
  // =========================
  Future<void> activate(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/activate'),
        headers: await headers(),
      ),
    );
  }

  Future<void> deactivate(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/deactivate'),
        headers: await headers(),
      ),
    );
  }

  Future<void> softDelete(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/softDelete'),
        headers: await headers(),
      ),
    );
  }
}
