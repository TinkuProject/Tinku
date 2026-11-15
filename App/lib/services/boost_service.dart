import 'dart:convert';
import '../../models/boost_model.dart';
import '../../models/business_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class BoostService extends BaseService<BoostModel> {
  BoostService(AuthService authService)
      : super("boosts", authService);

  @override
  BoostModel fromJson(Map<String, dynamic> json) {
    return BoostModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BoostModel model) {
    return model.toJson();
  }

  // =========================
// GET MINE (PROTECTED)
// =========================
  Future<List<BoostModel>> getMine() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/mine'),
        headers: await headers(),
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BoostModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<BusinessModel>> getPromotableBusinesses() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/promotable-businesses'),
        headers: await headers(),
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessModel>((e) => BusinessModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET ACTIVE (PUBLIC)
  // =========================
  Future<List<BoostModel>> getActive() async {
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
        .map<BoostModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY ENTITY (PUBLIC)
  // =========================
  Future<List<BoostModel>> getByEntity({
    required VisitEntity entityType,
    required int entityId,
  }) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/$endpoint/entity/${visitEntityToString(entityType)}/$entityId',
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BoostModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // CREATE (PROTECTED)
  // =========================
  Future<BoostModel> createBoost({
    required int entityId,
    required VisitEntity entityType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode({
          "entity_id": entityId,
          "entity_type": visitEntityToString(entityType),
          "start_date": startDate.toUtc().toIso8601String(),
          "end_date": endDate.toUtc().toIso8601String(),
        }),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // SOFT DELETE
  // =========================
  Future<void> softDelete(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/softDelete'),
        headers: await headers(),
      ),
    );
  }
}
