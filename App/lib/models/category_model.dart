import '../../core/enums.dart';
import 'media_model.dart';

class CategoryModel {
  final int id;
  final String name;
  final CategoryEntityType entityType;
  final BusinessType? businessType;
  final BasicStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  List<MediaModel>? media; // 👈 agregado

  CategoryModel({
    required this.id,
    required this.name,
    required this.entityType,
    this.businessType,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      entityType: categoryEntityTypeFromString(json['entity_type']),
      businessType: json['business_type'] != null
          ? businessTypeFromString(json['business_type'])
          : null,
      status: basicStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'entity_type': categoryEntityTypeToString(entityType),
      if (businessType != null)
        'business_type': businessTypeToString(businessType!),
      'status': basicStatusToString(status),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    CategoryEntityType? entityType,
    BusinessType? businessType,
    BasicStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MediaModel>? media,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      entityType: entityType ?? this.entityType,
      businessType: businessType ?? this.businessType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..media = media ?? this.media;
  }
}