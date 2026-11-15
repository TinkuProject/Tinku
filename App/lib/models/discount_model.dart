import '../../core/enums.dart';

class DiscountModel {
  final int id;
  final int businessId;
  final String? description;
  final double discountPercent;
  final DateTime startDate;
  final DateTime endDate;
  final PromotionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DiscountModel({
    required this.id,
    required this.businessId,
    this.description,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      id: json['id'],
      businessId: json['business_id'],
      description: json['description'],
      discountPercent: (json['discount_percent'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: promotionStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'description': description,
      'discount_percent': discountPercent,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'status': promotionStatusToString(status),
    };
  }
}