import '../../core/enums.dart';
import '../utils/json_read.dart';

class PaymentModel {
  final int id;
  final String userId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final String? externalReference;
  final PaymentType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    this.externalReference,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: readInt(json['id']),
      userId: readString(json['user_id']),
      method: paymentMethodFromString(readString(json['method'])),
      status: paymentStatusFromString(readString(json['status'])),
      amount: readDouble(json['amount']),
      currency: readString(json['currency'], fallback: 'BOB'),
      externalReference: json['external_reference']?.toString(),
      type: paymentTypeFromString(readString(json['type'])),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'method': paymentMethodToString(method),
      'status': paymentStatusToString(status),
      'amount': amount,
      'currency': currency,
      'external_reference': externalReference,
      'type': paymentTypeToString(type),
    };
  }
}

class CreatePaymentModel {
  final double amount;
  final PaymentMethod method;
  final PaymentType type;

  CreatePaymentModel({
    required this.amount,
    required this.method,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': paymentMethodToString(method),
      'type': paymentTypeToString(type),
    };
  }
}
