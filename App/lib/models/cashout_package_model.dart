import '../../core/enums.dart';
import '../utils/json_read.dart';

class CashoutPackageModel {
  final int id;
  final String name;
  final int tinkusAmount;
  final double cashAmount;
  final BasicStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CashoutPackageModel({
    required this.id,
    required this.name,
    required this.tinkusAmount,
    required this.cashAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory CashoutPackageModel.fromJson(Map<String, dynamic> json) {
    return CashoutPackageModel(
      id: readInt(json['id']),
      name: readString(json['name']),
      tinkusAmount: readInt(json['tinkus_amount']),
      cashAmount: readDouble(json['cash_amount']),
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
      'tinkus_amount': tinkusAmount,
      'cash_amount': cashAmount,
      'status': basicStatusToString(status),
    };
  }
}
