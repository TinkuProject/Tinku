import '../../core/enums.dart';

class MediaModel {
  final int id;
  final String entityId;
  final MediaEntityType entityType;
  final String url;
  final MediaType type;
  final String? description;
  final bool isPrimary;
  final int displayOrder;

  final DateTime createdAt;
  final DateTime? updatedAt;

  MediaModel({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.url,
    required this.type,
    this.description,
    required this.isPrimary,
    required this.displayOrder,
    required this.createdAt,
    this.updatedAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'],
      entityId: json['entity_id'].toString(),
      entityType: mediaEntityTypeFromString(json['entity_type']),
      url: json['url'],
      type: mediaTypeFromString(json['type']),
      description: json['description'],
      isPrimary: json['is_primary'] ?? false,
      displayOrder: json['display_order'] ?? 0,
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
      'entity_type': mediaEntityTypeToString(entityType),
      'url': url,
      'type': mediaTypeToString(type),
      'description': description,
      'is_primary': isPrimary,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}