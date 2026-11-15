import '../core/enums.dart';

class NearbyItemModel {
  final int entityId;
  final VisitEntity entityType;
  final String name;
  final double latitude;
  final double longitude;
  final double distance;
  final String? imageUrl;

  NearbyItemModel({
    required this.entityId,
    required this.entityType,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.imageUrl,
  });

  static int _toInt(dynamic value, String field) {
    if (value == null) {
      throw FormatException('$field es null');
    }
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      throw FormatException('$field es null');
    }

    return int.parse(text);
  }

  static double _toDouble(dynamic value, String field) {
    if (value == null) {
      throw FormatException('$field es null');
    }
    if (value is double) return value;
    if (value is num) return value.toDouble();

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      throw FormatException('$field es null');
    }

    return double.parse(text);
  }

  factory NearbyItemModel.fromJson(Map<String, dynamic> json) {
    return NearbyItemModel(
      entityId: _toInt(
        json['entity_id'] ?? json['entityId'] ?? json['id'],
        'entityId',
      ),
      entityType: visitEntityFromString(
        (json['entity_type'] ?? json['entityType'] ?? json['type']).toString(),
      ),
      name: json['name']?.toString() ?? '',
      latitude: _toDouble(json['latitude'], 'latitude'),
      longitude: _toDouble(json['longitude'], 'longitude'),
      distance: _toDouble(json['distance'], 'distance'),
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString(),
    );
  }
}