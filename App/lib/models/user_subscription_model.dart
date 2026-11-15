import '../core/enums.dart';
import '../utils/json_read.dart';

class UserSubscriptionModel {
  final int id;
  final String userId;
  final int planId;
  final DateTime startDate;
  final DateTime? endDate;
  final SubscriptionStatus status;

  UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    this.endDate,
    required this.status,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: readInt(json['id']),
      userId: readString(json['user_id']),
      planId: readInt(json['plan_id']),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      status: subscriptionStatusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'status': subscriptionStatusToString(status),
    };
  }
}
