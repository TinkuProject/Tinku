import 'dart:convert';

import '../../models/media_model.dart';
import '../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class MediaService extends BaseService<MediaModel> {
  MediaService(AuthService authService) : super("media", authService);

  @override
  MediaModel fromJson(Map<String, dynamic> json) {
    return MediaModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(MediaModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY ENTITY (PUBLIC)
  // =========================
  Future<List<MediaModel>> getByEntity({
    required String entityId,
    required MediaEntityType entityType,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/entity').replace(queryParameters: {
      'entity_id': entityId.toString(),
      'entity_type': mediaEntityTypeToString(entityType),
    });

    final response = await request(
      () async => client.get(uri, headers: await headers()),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<MediaModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET PRIMARY (PUBLIC)
  // =========================
  Future<MediaModel?> getPrimary({
    required String entityId,
    required MediaEntityType entityType,
  }) async {
    final uri =
        Uri.parse('$baseUrl/$endpoint/entity/primary').replace(queryParameters: {
      'entity_id': entityId,
      'entity_type': mediaEntityTypeToString(entityType),
    });

    final response = await client.get(uri, headers: await headers());

    if (response.statusCode == 404) return null;
    if (response.body == 'null' || response.body.isEmpty) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data == null) return null;

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return fromJson(data);
  }

  Future<Map<int, List<MediaModel>>> getByEntities({
    required List<int> entityIds,
    required MediaEntityType entityType,
  }) async {
    if (entityIds.isEmpty) return {};

    final uri = Uri.parse('$baseUrl/$endpoint/entities').replace(
      queryParameters: {
        'entity_ids': entityIds.join(','),
        'entity_type': mediaEntityTypeToString(entityType),
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

  Future<Map<String, List<MediaModel>>> getByEntityIds({
    required List<String> entityIds,
    required MediaEntityType entityType,
  }) async {
    if (entityIds.isEmpty) return {};

    final uniqueIds = entityIds.toSet().toList();
    final uri = Uri.parse('$baseUrl/$endpoint/entities').replace(
      queryParameters: {
        'entity_ids': uniqueIds.join(','),
        'entity_type': mediaEntityTypeToString(entityType),
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
        key,
        (value as List)
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    });
  }
}
