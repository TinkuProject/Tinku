import '../../core/enums.dart';

class BoostModel {
  final int id;
  final int entityId;
  final VisitEntity entityType;
  final DateTime startDate;
  final DateTime endDate;
  final PromotionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BoostModel({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory BoostModel.fromJson(Map<String, dynamic> json) {
    final endDate = DateTime.parse(json['end_date']);
    final status = promotionStatusFromString(json['status']);

    return BoostModel(
      id: json['id'],
      entityId: json['entity_id'],
      entityType: visitEntityFromString(json['entity_type']),
      startDate: DateTime.parse(json['start_date']),
      endDate: endDate,
      status: status == PromotionStatus.active &&
              endDate.isBefore(DateTime.now())
          ? PromotionStatus.inactive
          : status,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_id': entityId,
      'entity_type': visitEntityToString(entityType),
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'status': promotionStatusToString(status),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
