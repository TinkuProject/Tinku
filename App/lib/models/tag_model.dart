import '../../core/enums.dart';

class TagModel {
  final int id;
  final String name;
  final String? description;
  final BasicStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TagModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
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
      'description': description,
      'status': basicStatusToString(status),
    };
  }
}