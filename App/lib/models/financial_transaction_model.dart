import '../../core/enums.dart';
import '../utils/date/local_date_parser.dart';

class FinancialTransactionModel {
  final int id;
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency;
  final String? purpose;
  final int? referenceId;
  final int? paymentId;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FinancialTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.purpose,
    this.referenceId,
    this.paymentId,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory FinancialTransactionModel.fromJson(Map<String, dynamic> json) {
    return FinancialTransactionModel(
      id: json['id'],
      userId: json['user_id'],
      type: transactionTypeFromString(json['type']),
      status: transactionStatusFromString(json['status']),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      purpose: json['purpose'],
      referenceId: json['reference_id'],
      paymentId: json['payment_id'],
      description: json['description'],
      createdAt: LocalDateParser.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? LocalDateParser.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': transactionTypeToString(type),
      'status': transactionStatusToString(status),
      'amount': amount,
      'currency': currency,
      'purpose': purpose,
      'reference_id': referenceId,
      'payment_id': paymentId,
      'description': description,
    };
  }
}
