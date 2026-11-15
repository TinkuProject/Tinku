import '../../core/enums.dart';

class CertificationModel {
  final int id;
  final int businessId;
  final String name;
  final String? licenseNumber;
  final BasicStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CertificationModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.licenseNumber,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['id'],
      businessId: json['business_id'],
      name: json['name'],
      licenseNumber: json['license_number']?.toString(),
      status: basicStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'name': name,
      'license_number': licenseNumber,
      'status': basicStatusToString(status),
    };
  }
}
