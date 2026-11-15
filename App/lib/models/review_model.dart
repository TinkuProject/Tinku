import '../../core/enums.dart';
import 'media_model.dart';

class ReviewModel {
  final int id;
  final String userId;
  final ReviewEntityType entityType;
  final int entityId;
  final double rating;
  final String? comment;
  final String? ownerReply;
  final String? ownerReplyUserId;
  final DateTime? ownerReplyAt;
  final String? entityName;
  final String? entityKind;
  final int? entityBusinessId;
  final String? reviewerUsername;
  final String? reviewerFirstName;
  final String? reviewerLastName;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  List<MediaModel>? media;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.rating,
    this.comment,
    this.ownerReply,
    this.ownerReplyUserId,
    this.ownerReplyAt,
    this.entityName,
    this.entityKind,
    this.entityBusinessId,
    this.reviewerUsername,
    this.reviewerFirstName,
    this.reviewerLastName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      userId: json['user_id'].toString(),
      entityType: reviewEntityTypeFromString(json['entity_type'].toString()),
      entityId: json['entity_id'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment']?.toString(),
      ownerReply: json['owner_reply']?.toString(),
      ownerReplyUserId: json['owner_reply_user_id']?.toString(),
      ownerReplyAt: json['owner_reply_at'] != null
          ? DateTime.tryParse(json['owner_reply_at'].toString())
          : null,
      entityName: json['entity_name']?.toString(),
      entityKind: json['entity_kind']?.toString(),
      entityBusinessId: json['entity_business_id'] == null
          ? null
          : int.tryParse(json['entity_business_id'].toString()),
      reviewerUsername: json['reviewer_username']?.toString(),
      reviewerFirstName: json['reviewer_first_name']?.toString(),
      reviewerLastName: json['reviewer_last_name']?.toString(),
      status: reviewStatusFromString(json['status'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'entity_type': reviewEntityTypeToString(entityType),
      'entity_id': entityId,
      'rating': rating,
      'comment': comment,
      'owner_reply': ownerReply,
      'owner_reply_user_id': ownerReplyUserId,
      'owner_reply_at': ownerReplyAt?.toIso8601String(),
      'status': reviewStatusToString(status),
    };
  }

  ReviewModel copyWith({
    int? id,
    String? userId,
    ReviewEntityType? entityType,
    int? entityId,
    double? rating,
    String? comment,
    String? ownerReply,
    String? ownerReplyUserId,
    DateTime? ownerReplyAt,
    String? entityName,
    String? entityKind,
    int? entityBusinessId,
    String? reviewerUsername,
    String? reviewerFirstName,
    String? reviewerLastName,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MediaModel>? media,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      ownerReply: ownerReply ?? this.ownerReply,
      ownerReplyUserId: ownerReplyUserId ?? this.ownerReplyUserId,
      ownerReplyAt: ownerReplyAt ?? this.ownerReplyAt,
      entityName: entityName ?? this.entityName,
      entityKind: entityKind ?? this.entityKind,
      entityBusinessId: entityBusinessId ?? this.entityBusinessId,
      reviewerUsername: reviewerUsername ?? this.reviewerUsername,
      reviewerFirstName: reviewerFirstName ?? this.reviewerFirstName,
      reviewerLastName: reviewerLastName ?? this.reviewerLastName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..media = media ?? this.media;
  }
}
