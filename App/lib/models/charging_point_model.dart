import '../../core/enums.dart';

class ChargingPointModel {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final ChargingPointStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChargingPointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChargingPointModel.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    final location = json['location'];

    if (location != null) {
      if (location['coordinates'] != null) {
        final coords = location['coordinates'];
        if (coords is List && coords.length == 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      } else {
        lat = (location['latitude'] as num?)?.toDouble() ?? 0;
        lng = (location['longitude'] as num?)?.toDouble() ?? 0;
      }
    }

    return ChargingPointModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: lat,
      longitude: lng,
      status: chargingPointStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude], // SIEMPRE así
      },
      'status': chargingPointStatusToString(status),
    };
  }
}