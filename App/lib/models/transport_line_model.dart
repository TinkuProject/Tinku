import '../core/enums.dart';

class TransportLineModel {
  final int id;
  final int vehicleTypeId;
  final String name;
  final BasicStatus status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  TransportLineModel({
    required this.id,
    required this.vehicleTypeId,
    required this.name,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportLineModel.fromJson(Map<String, dynamic> json) {
    return TransportLineModel(
      id: json['id'],
      vehicleTypeId: json['vehicle_type_id'],
      name: json['name'],
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
      'vehicle_type_id': vehicleTypeId,
      'name': name,
      'status': basicStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}