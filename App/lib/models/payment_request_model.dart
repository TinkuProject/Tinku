import '../../core/enums.dart';
import '../utils/json_read.dart';

class PaymentRequestModel {
  final int id;
  final String userId;
  final int paymentId;

  final PaymentType type;
  final int? targetId;

  final ApprovalStatus status;
  final String? comment;

  final String? reviewedBy;
  final DateTime? reviewedAt;

  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentRequestModel({
    required this.id,
    required this.userId,
    required this.paymentId,
    required this.type,
    this.targetId,
    required this.status,
    this.comment,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return PaymentRequestModel(
      id: readInt(json['id']),
      userId: readString(json['userId'] ?? json['user_id']),
      paymentId: readInt(json['paymentId'] ?? json['payment_id']),

      type: paymentTypeFromString(readString(json['type'])),
      targetId: readNullableInt(json['targetId'] ?? json['target_id']),

      status: approvalStatusFromString(readString(json['status'])),
      comment: json['comment']?.toString(),

      reviewedBy: (json['reviewedBy'] ?? json['reviewed_by'])?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'])
          : json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'])
          : null,

      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'type': paymentTypeToString(type), // 🔥 obligatorio

      if (targetId != null) 'targetId': targetId,

      'status': approvalStatusToString(status),
      'comment': comment,
    };
  }

  PaymentRequestModel copyWith({
    int? id,
    String? userId,
    int? paymentId,
    PaymentType? type,
    int? targetId,
    ApprovalStatus? status,
    String? comment,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      paymentId: paymentId ?? this.paymentId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
