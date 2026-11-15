import '../core/enums.dart';

class CreateUserVisitModel {
  final VisitEntity entityType;
  final int entityId;
  final VisitType type;

  CreateUserVisitModel({
    required this.entityType,
    required this.entityId,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity_type': visitEntityToString(entityType),
      'entity_id': entityId,
      'type': visitTypeToString(type),
    };
  }
}

class UserVisitModel {
  final int id;
  final String userId;
  final VisitEntity entityType;
  final int entityId;
  final VisitType type;

  final DateTime createdAt;

  UserVisitModel({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.type,
    required this.createdAt,
  });

  factory UserVisitModel.fromJson(Map<String, dynamic> json) {
    return UserVisitModel(
      id: json['id'],
      userId: json['user_id'],
      entityType: visitEntityFromString(json['entity_type']),
      entityId: json['entity_id'],
      type: visitTypeFromString(json['type']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entity_type': visitEntityToString(entityType),
      'entity_id': entityId,
      'type': visitTypeToString(type),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}