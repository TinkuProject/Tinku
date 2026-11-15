import '../../core/enums.dart';
import 'business_model.dart';

class BusinessClaimRequestModel {
  final int id;
  final int businessId;
  final String userId;
  final ApprovalStatus status;
  final String? comment;
  final List<String> documents;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final BusinessModel? business;

  BusinessClaimRequestModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.status,
    this.comment,
    required this.documents,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.business,
  });

  factory BusinessClaimRequestModel.fromJson(Map<String, dynamic> json) {
    return BusinessClaimRequestModel(
      id: json['id'],
      businessId: json['business_id'],
      userId: json['user_id'],
      status: approvalStatusFromString(json['status']),
      comment: json['comment'],
      documents: List<String>.from(json['documents'] ?? []),
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      business: json['business'] is Map<String, dynamic>
          ? BusinessModel.fromJson(Map<String, dynamic>.from(json['business']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'user_id': userId,
      'status': approvalStatusToString(status),
      'comment': comment,
      'documents': documents,
    };
  }
}
