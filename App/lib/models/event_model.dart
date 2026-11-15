import '../../core/enums.dart';
import '../utils/parsers/parse_utils.dart';

class EventModel {
  final int id;
  final int? businessId;
  final String creatorId;
  final int categoryId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final int? capacity;
  final int? attendeesCount;
  final int? tinkuPrice;
  final String address;
  final double latitude;
  final double longitude;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.id,
    this.businessId,
    required this.creatorId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.capacity,
    this.attendeesCount,
    this.tinkuPrice,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    final location = json['location'];

    if (location != null) {
      lat = parseDouble(location['latitude']);
      lng = parseDouble(location['longitude']);
    }

    return EventModel(
      id: json['id'],
      businessId: json['business_id'],
      creatorId: json['creator_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']).toLocal(),
      endDate: DateTime.parse(json['end_date']).toLocal(),
      capacity: json['capacity'],
      attendeesCount: json['attendees_count'],
      tinkuPrice: json['tinku_price'] != null
          ? (json['tinku_price'] as num).toInt()
          : null,
      address: json['address'],
      latitude: lat,
      longitude: lng,
      status: eventStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'capacity': capacity,
      'tinku_price': tinkuPrice,
      'address': address,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'status': eventStatusToString(status),
    };
  }
}