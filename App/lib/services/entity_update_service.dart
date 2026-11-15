import 'dart:convert';
import '../../models/entity_update_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class EntityUpdateService extends BaseService<EntityUpdateModel> {
  EntityUpdateService(AuthService authService)
      : super("entity-updates", authService);

  @override
  EntityUpdateModel fromJson(Map<String, dynamic> json) {
    return EntityUpdateModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(EntityUpdateModel model) {
    return model.toJson();
  }

  // =========================
  // CREATE
  // =========================
  @override
  Future<EntityUpdateModel> create(EntityUpdateModel model) async {
    final response = await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(model.toJson()),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // GET MINE
  // =========================
  Future<List<EntityUpdateModel>> getMine() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<EntityUpdateModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY ENTITY
  // =========================
  Future<List<EntityUpdateModel>> getByEntity({
    required UpdateEntityType entityType,
    required int entityId,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/entity').replace(
      queryParameters: {
        'entity_type': updateEntityTypeToString(entityType),
        'entity_id': entityId.toString(),
      },
    );

    final response = await request(
          () async => client.get(uri, headers: await headers()),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<EntityUpdateModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // APPROVE
  // =========================
  Future<void> approve(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/approve'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // REJECT
  // =========================
  Future<void> reject(int id, {String? comment}) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/reject'),
        headers: await headers(),
        body: jsonEncode({
          if (comment != null) "comment": comment,
        }),
      ),
    );
  }
}