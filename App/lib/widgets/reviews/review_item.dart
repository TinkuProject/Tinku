import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../ui/themes/colors.dart';
import 'review_stars.dart';
import '../common/network_image_with_loader.dart';

class ReviewItem extends StatelessWidget {
  final String username;
  final String? userPhoto;
  final double rating;
  final String? comment;
  final String? ownerReply;
  final DateTime? ownerReplyAt;
  final String? image;
  final DateTime createdAt;
  final bool isMine;
  final VoidCallback? onEdit;

  const ReviewItem({
    super.key,
    required this.username,
    required this.userPhoto,
    required this.rating,
    required this.comment,
    this.ownerReply,
    this.ownerReplyAt,
    required this.image,
    required this.createdAt,
    this.isMine = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(createdAt);

    final usernameStyle =
    Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    final commentStyle =
        Theme.of(context).textTheme.bodyMedium;

    final dateStyle =
    Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// AVATAR
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceSoft,
            backgroundImage:
            userPhoto != null ? NetworkImage(userPhoto!) : null,
            child: userPhoto == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// USERNAME + BADGE
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: usernameStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (isMine)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Tu reseña",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                /// STARS + DATE
                Row(
                  children: [
                    ReviewStars(
                      rating: rating,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(date, style: dateStyle),
                  ],
                ),

                /// COMMENT
                if (comment != null && comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(comment!, style: commentStyle),
                ],

                /// IMAGE
                if (image != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkImageWithLoader(
                      imageUrl: image,
                      height: 180,
                      width: double.infinity,
                    ),
                  ),
                ],

                if (ownerReply != null && ownerReply!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.darkBlue.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Respuesta del negocio',
                          style: TextStyle(
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(ownerReply!, style: commentStyle),
                      ],
                    ),
                  ),
                ],

                /// EDIT
                if (isMine && onEdit != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Editar reseña"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkBlue,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
