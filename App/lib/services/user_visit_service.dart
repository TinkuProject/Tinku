import 'dart:convert';
import '../../models/user_visit_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class UserVisitService extends BaseService<UserVisitModel> {
  UserVisitService(AuthService authService)
      : super("user-visits", authService);

  @override
  UserVisitModel fromJson(Map<String, dynamic> json) {
    return UserVisitModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(UserVisitModel model) {
    return model.toJson();
  }

  Future<UserVisitModel> createVisit(CreateUserVisitModel model) async {
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
  // GET MY VISITS
  // =========================
  Future<List<UserVisitModel>> getMine() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/my'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    return (data as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY ENTITY
  // =========================
  Future<List<UserVisitModel>> getByEntity({
    required VisitEntity entityType,
    required int entityId,
  }) async {
    final response = await request(
          () async => client.get(
        Uri.parse(
          '$baseUrl/$endpoint/entity/${visitEntityToString(entityType)}/$entityId',
        ),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    return (data as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET ENTITY COUNTS (BATCH)
  // =========================
  Future<Map<int, int>> getEntityCounts({
    required VisitEntity entityType,
    required List<int> entityIds,
    VisitType type = VisitType.visited,
  }) async {
    if (entityIds.isEmpty) return {};

    final uri = Uri.parse('$baseUrl/$endpoint/entity-counts').replace(
      queryParameters: {
        'entity_type': visitEntityToString(entityType),
        'ids': entityIds.join(','),
        'type': visitTypeToString(type),
      },
    );

    final response = await request(
          () async => client.get(
        uri,
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data.map(
      (key, value) => MapEntry(
        int.tryParse(key) ?? 0,
        value is int ? value : int.tryParse(value.toString()) ?? 0,
      ),
    )..removeWhere((key, _) => key <= 0);
  }

  // =========================
  // DELETE BY ENTITY
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
}
