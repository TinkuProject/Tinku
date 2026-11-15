import '../core/enums.dart';
import '../utils/json_read.dart';

class CashoutRequestModel {
  const CashoutRequestModel({
    required this.id,
    required this.userId,
    required this.cashoutPackageId,
    required this.status,
    required this.tinkusAmount,
    required this.cashAmount,
    required this.createdAt,
    this.comment,
    this.reviewedAt,
  });

  final int id;
  final String userId;
  final int cashoutPackageId;
  final ApprovalStatus status;
  final int tinkusAmount;
  final double cashAmount;
  final String? comment;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  factory CashoutRequestModel.fromJson(Map<String, dynamic> json) {
    return CashoutRequestModel(
      id: readInt(json['id']),
      userId: readString(json['user_id']),
      cashoutPackageId: readInt(json['cashout_package_id']),
      status: approvalStatusFromString(readString(json['status'])),
      tinkusAmount: readInt(json['tinkus_amount']),
      cashAmount: readDouble(json['cash_amount']),
      comment: json['comment']?.toString(),
      createdAt: DateTime.parse(readString(json['created_at'])),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
    );
  }
}
