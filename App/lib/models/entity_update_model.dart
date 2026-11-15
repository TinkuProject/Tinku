import '../../core/enums.dart';

class EntityUpdateModel {
  final int id;
  final UpdateEntityType entityType;
  final int entityId;
  final String creatorId;
  final Map<String, dynamic> data;
  final ApprovalStatus status;
  final String? comment;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  EntityUpdateModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.creatorId,
    required this.data,
    required this.status,
    this.comment,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory EntityUpdateModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return EntityUpdateModel(
      id: json['id'],
      entityType: updateEntityTypeFromString(
        json['entity_type'],
      ),
      entityId: json['entity_id'],
      creatorId: json['creator_id'],
      data: Map<String, dynamic>.from(
        json['data'] ?? {},
      ),
      status: approvalStatusFromString(
        json['status'],
      ),
      comment: json['comment'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_type':
      updateEntityTypeToString(entityType),

      'entity_id': entityId,

      'data': data,
    };
  }
}