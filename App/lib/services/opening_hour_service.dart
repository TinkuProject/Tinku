import 'dart:convert';
import '../../models/opening_hour_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class OpeningHourService extends BaseService<OpeningHourModel> {
  OpeningHourService(AuthService authService)
      : super("opening-hours", authService);

  @override
  OpeningHourModel fromJson(Map<String, dynamic> json) {
    return OpeningHourModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(OpeningHourModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY ENTITY
  // =========================
  Future<List<OpeningHourModel>> getByEntity({
    required OpeningEntity entityType,
    required int entityId,
  }) async {
    final response = await request(
          () async => client.get(
        Uri.parse(
          '$baseUrl/$endpoint/${openingEntityToString(entityType)}/$entityId',
        ),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<OpeningHourModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<int, List<OpeningHourModel>>> getByEntities({
    required OpeningEntity entityType,
    required List<int> entityIds,
  }) async {
    if (entityIds.isEmpty) return {};

    final uniqueIds = entityIds.toSet().toList();
    final uri = Uri.parse('$baseUrl/$endpoint/entities').replace(
      queryParameters: {
        'entity_type': openingEntityToString(entityType),
        'entity_ids': uniqueIds.join(','),
      },
    );

    final response = await request(
      () async => client.get(uri, headers: await headers()),
    );

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
  Future<OpeningHourModel> updateHour(
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
  // DELETE ONE
  // =========================
  Future<void> deleteHour(int id) async {
    await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // DELETE BY ENTITY
  // =========================
  Future<void> deleteByEntity({
    required OpeningEntity entityType,
    required int entityId,
  }) async {
    await request(
          () async => client.delete(
        Uri.parse(
          '$baseUrl/$endpoint/${openingEntityToString(entityType)}/$entityId',
        ),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // REPLACE ALL
  // =========================
  Future<void> replaceAll({
    required OpeningEntity entityType,
    required int entityId,
    required List<OpeningHourModel> hours,
  }) async {
    await request(
          () async => client.put(
        Uri.parse(
          '$baseUrl/$endpoint/${openingEntityToString(entityType)}/$entityId',
        ),
        headers: await headers(),
        body: jsonEncode(
          hours.map((e) => e.toJson()).toList(),
        ),
      ),
    );
  }
}
