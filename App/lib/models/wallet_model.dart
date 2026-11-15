import '../utils/json_read.dart';

class WalletModel {
  final String userId;
  final double balance;

  final DateTime createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.userId,
    required this.balance,
    required this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: readString(json['user_id']),
      balance: readDouble(json['balance']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'balance': balance,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
