import '../../../models/entity_update_model.dart';
import '../../../core/enums.dart';
import '../../../services/entity_update_service.dart';

class EntityUpdateController {
  EntityUpdateController(this._service);

  final EntityUpdateService _service;

  /// Crea una solicitud de actualización en estado pendiente.
  /// El [data] se sanitiza para que sea JSON-safe antes de enviar.
  Future<EntityUpdateModel> submit({
    required UpdateEntityType entityType,
    required int entityId,
    required String creatorId,
    required Map<String, dynamic> data,
    List<String> addedMediaUrls = const [],
    List<int> removedMediaIds = const [],
  }) async {
    final payload = _sanitizeMap(data);

    if (addedMediaUrls.isNotEmpty || removedMediaIds.isNotEmpty) {
      payload['media'] = buildMediaPayload(
        add: addedMediaUrls,
        remove: removedMediaIds,
      );
    }

    final update = EntityUpdateModel(
      id: 0,
      entityType: entityType,
      entityId: entityId,
      creatorId: creatorId,
      data: payload,
      status: ApprovalStatus.pending,
      createdAt: DateTime.now(),
    );

    return _service.create(update);
  }

  /// Útil si quieres construir el bloque de media manualmente.
  Map<String, dynamic> buildMediaPayload({
    List<String> add = const [],
    List<int> remove = const [],
  }) {
    return {
      'add': add,
      'remove': remove,
    };
  }

  /// Alias cómodo para casos donde sí o sí hay media.
  Future<EntityUpdateModel> submitWithMedia({
    required UpdateEntityType entityType,
    required int entityId,
    required String creatorId,
    required Map<String, dynamic> data,
    required List<String> addedMediaUrls,
    List<int> removedMediaIds = const [],
  }) {
    return submit(
      entityType: entityType,
      entityId: entityId,
      creatorId: creatorId,
      data: data,
      addedMediaUrls: addedMediaUrls,
      removedMediaIds: removedMediaIds,
    );
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    return input.map((key, value) {
      return MapEntry(
        key,
        _jsonSafe(value),
      );
    });
  }

  dynamic _jsonSafe(dynamic value) {
    if (value == null ||
        value is num ||
        value is String ||
        value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Enum) {
      return value.name;
    }

    if (value is Map) {
      return value.map(
            (key, val) => MapEntry(
          key.toString(),
          _jsonSafe(val),
        ),
      );
    }

    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }

    try {
      final dynamic json = (value as dynamic).toJson();
      return _jsonSafe(json);
    } catch (_) {
      return value.toString();
    }
  }
}