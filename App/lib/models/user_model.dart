import '../../core/enums.dart';
import 'media_model.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? ci;
  final String? address;
  final double? latitude;
  final double? longitude;
  final UserRole role;
  final UserStatus status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  List<MediaModel>? media;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.ci,
    this.address,
    this.latitude,
    this.longitude,
    required this.role,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    double? latitude;
    double? longitude;

    final raw = safeJson['location'];

    if (raw is Map && raw['coordinates'] is List) {
      final c = raw['coordinates'];
      if (c.length == 2) {
        longitude = (c[0] as num).toDouble();
        latitude = (c[1] as num).toDouble();
      }
    } else if (raw is Map &&
        raw['latitude'] is num &&
        raw['longitude'] is num) {
      latitude = (raw['latitude'] as num).toDouble();
      longitude = (raw['longitude'] as num).toDouble();
    }

    if (latitude != null &&
        longitude != null &&
        !_looksLikeBoliviaPoint(latitude, longitude) &&
        _looksLikeBoliviaPoint(longitude, latitude)) {
      final originalLatitude = latitude;
      latitude = longitude;
      longitude = originalLatitude;
    }

    return UserModel(
      id: safeJson['id'],
      username: safeJson['username'],
      email: safeJson['email'],
      firstName: safeJson['first_name'],
      lastName: safeJson['last_name'],
      phone: safeJson['phone'],
      ci: safeJson['ci'],
      address: safeJson['address'],
      latitude: latitude,
      longitude: longitude,
      role: userRoleFromString(safeJson['role']),
      status: userStatusFromString(safeJson['status']),
      createdAt: DateTime.parse(safeJson['created_at']),
      updatedAt: safeJson['updated_at'] != null
          ? DateTime.parse(safeJson['updated_at'])
          : null,
    );
  }

  static bool _looksLikeBoliviaPoint(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude >= -23.5 &&
        latitude <= -9.0 &&
        longitude >= -70.5 &&
        longitude <= -57.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'ci': ci,
      'address': address,
      'location': latitude != null && longitude != null
          ? {
              'type': 'Point',
              'coordinates': [longitude, latitude],
            }
          : null,
      'role': userRoleToString(role),
      'status': userStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? ci,
    String? address,
    double? latitude,
    double? longitude,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MediaModel>? media, // 👈 agregado
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      ci: ci ?? this.ci,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..media = media ?? this.media;
  }
}
