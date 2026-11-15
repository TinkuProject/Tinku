import '../core/enums.dart';

class TouristPlaceModel {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final String? address;
  final String? createdBy;
  final String? categoryName;
  final String? primaryImageUrl;

  final double latitude;
  final double longitude;

  final BasicStatus status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  TouristPlaceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.address,
    this.createdBy,
    this.categoryName,
    this.primaryImageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory TouristPlaceModel.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    final location = json['location'];

    if (location != null) {
      lat = (location['latitude'] as num).toDouble();
      lng = (location['longitude'] as num).toDouble();
    }

    return TouristPlaceModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      createdBy: json['created_by']?.toString(),
      categoryName: json['category_name'],
      primaryImageUrl: json['primary_image_url'],
      latitude: lat,
      longitude: lng,
      status: basicStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'address': address,
      'created_by': createdBy,
      'category_name': categoryName,
      'primary_image_url': primaryImageUrl,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'status': basicStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
