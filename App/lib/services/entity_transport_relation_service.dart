import 'dart:convert';
import '../../models/entity_transport_relation_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class EntityTransportRelationService
    extends BaseService<EntityTransportRelationModel> {
  EntityTransportRelationService(AuthService authService)
      : super("entity-transport-relations", authService);

  @override
  EntityTransportRelationModel fromJson(Map<String, dynamic> json) {
    return EntityTransportRelationModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(EntityTransportRelationModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY ENTITY (PUBLIC)
  // =========================
  Future<List<EntityTransportRelationModel>> getByEntity({
    required VisitEntity entityType,
    required int entityId,
  }) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/$endpoint/${visitEntityToString(entityType)}/$entityId',
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    return data
        .map<EntityTransportRelationModel>((e) => fromJson(e))
        .toList();
  }

  Future<Map<int, List<EntityTransportRelationModel>>> getByEntities({
    required VisitEntity entityType,
    required List<int> entityIds,
  }) async {
    if (entityIds.isEmpty) return {};

    final uniqueIds = entityIds.toSet().toList();
    final uri = Uri.parse('$baseUrl/$endpoint/entities').replace(
      queryParameters: {
        'entity_type': visitEntityToString(entityType),
        'entity_ids': uniqueIds.join(','),
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
  // CREATE (PROTECTED)
  // =========================
  Future<void> createRelation(EntityTransportRelationModel model) async {
    await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(model.toJson()),
      ),
    );
  }

  // =========================
  // DELETE ONE
  // =========================
  Future<void> deleteRelation({
    required VisitEntity entityType,
    required int entityId,
    required int lineId,
  }) async {
    await request(
          () async => client.delete(
        Uri.parse(
          '$baseUrl/$endpoint/${visitEntityToString(entityType)}/$entityId/$lineId',
        ),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // DELETE ALL BY ENTITY
  // =========================
  Future<void> deleteByEntity({
    required VisitEntity entityType,
    required int entityId,
  }) async {
    await request(
          () async => client.delete(
        Uri.parse(
          '$baseUrl/$endpoint/${visitEntityToString(entityType)}/$entityId',
        ),
        headers: await headers(),
      ),
    );
  }

  Future<void> replaceLines({
    required VisitEntity entityType,
    required int entityId,
    required List<int> newLineIds,
  }) async {
    await request(
          () async => client.put(
        Uri.parse(
          '$baseUrl/$endpoint/${visitEntityToString(entityType)}/$entityId',
        ),
        headers: await headers(),
        body: jsonEncode({
          'line_ids': newLineIds,
        }),
      ),
    );
  }
}
