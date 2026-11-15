import '../../core/enums.dart';

class EntityTransportRelationModel {
  final VisitEntity entityType;
  final int entityId;
  final int transportLineId;

  EntityTransportRelationModel({
    required this.entityType,
    required this.entityId,
    required this.transportLineId,
  });

  factory EntityTransportRelationModel.fromJson(Map<String, dynamic> json) {
    return EntityTransportRelationModel(
      entityType: visitEntityFromString(json['entity_type']),
      entityId: json['entity_id'],
      transportLineId: json['transport_line_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_type': visitEntityToString(entityType),
      'entity_id': entityId,
      'transport_line_id': transportLineId,
    };
  }
}