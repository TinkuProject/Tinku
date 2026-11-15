import 'dart:convert';

import '../../core/enums.dart';
import '../utils/parsers/parse_utils.dart';

class BusinessModel {
  final int id;
  final int categoryId;
  final String? ownerId;
  final String name;
  final String? nit;
  final String? description;
  final String? phone;
  final String? email;
  final BusinessType businessType;
  final String address;
  final double latitude;
  final double longitude;
  final String? website;
  final bool validated;
  final BusinessStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessModel({
    required this.id,
    required this.categoryId,
    this.ownerId,
    required this.name,
    this.nit,
    this.description,
    this.phone,
    this.email,
    required this.businessType,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.website,
    required this.validated,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    final rawLocation = json['location'];

    if (rawLocation is Map<String, dynamic>) {
      lat = parseDouble(rawLocation['latitude']);
      lng = parseDouble(rawLocation['longitude']);
    } else if (rawLocation is String) {
      try {
        final decoded = jsonDecode(rawLocation);
        if (decoded is Map<String, dynamic>) {
          lat = parseDouble(decoded['latitude']);
          lng = parseDouble(decoded['longitude']);
        }
      } catch (_) {
        // si falla, ignoramos (evita crash)
      }
    }

    return BusinessModel(
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      ownerId: json['owner_id'],
      name: json['name'] ?? '',
      nit: json['nit'],
      description: json['description'],
      phone: json['phone'],
      email: json['email'],
      businessType: businessTypeFromString(json['business_type']),
      address: json['address'] ?? '',
      latitude: lat,
      longitude: lng,
      website: json['website'],
      validated: parseBool(json['validated']),
      status: businessStatusFromString(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'owner_id': ownerId,
      'name': name,
      'nit': nit,
      'description': description,
      'phone': phone,
      'email': email,
      'business_type': businessTypeToString(businessType),
      'address': address,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'website': website,
      'validated': validated,
      'status': businessStatusToString(status),
    };
  }
}