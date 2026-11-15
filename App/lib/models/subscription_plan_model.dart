import '../../core/enums.dart';
import '../utils/json_read.dart';

class SubscriptionPlanModel {
  final int id;
  final String name;
  final double price;
  final String currency;
  final int durationMonths;
  final int includedTinku;
  final BasicStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.durationMonths,
    required this.includedTinku,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: readInt(json['id']),
      name: readString(json['name']),
      price: readDouble(json['price']),
      currency: readString(json['currency'], fallback: 'BOB'),
      durationMonths: readInt(json['duration_months'], fallback: 1),
      includedTinku: readInt(json['included_tinku']),
      status: basicStatusFromString(readString(json['status'])),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'duration_months': durationMonths,
      'included_tinku': includedTinku,
      'status': basicStatusToString(status),
    };
  }
}
