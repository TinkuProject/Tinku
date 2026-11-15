import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/shared/review/reviews_controller.dart';
import '../../core/enums.dart';
import '../../providers/user_provider.dart';
import '../../ui/themes/colors.dart';

import '../../extensions/user_extension.dart';
import '../../extensions/review_extension.dart';

import '../common/empty/app_empty.dart';
import 'review_item.dart';
import 'review_editor.dart';
import 'review_stars.dart';

class ReviewsSection extends StatelessWidget {
  final ReviewsController controller;
  final int targetId;
  final ReviewEntityType targetType;
  final String ownerUserId;
  final bool canWriteReview;
  final String? blockedMessage;

  const ReviewsSection({
    super.key,
    required this.controller,
    required this.targetId,
    required this.targetType,
    required this.ownerUserId,
    this.canWriteReview = true,
    this.blockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final r = controller;
        final user = context.watch<UserProvider>().user;

        final reviewWidgets = r.reviews.map((review) {
          final reviewUser = r.userCache[review.userId];
          final currentUser = context.read<UserProvider>().user;
          final isMine = review.userId == currentUser?.id;

          return Column(
            children: [
              const Divider(),
              ReviewItem(
                username: reviewUser?.username ?? "Usuario",
                userPhoto: reviewUser?.photoUrl,
                rating: review.rating,
                comment: review.comment,
                ownerReply: review.ownerReply,
                ownerReplyAt: review.ownerReplyAt,
                image: review.imageUrl,
                createdAt: review.createdAt,
                isMine: isMine,
                onEdit: isMine && canWriteReview
                    ? () {
                        r.startEditing();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => ReviewEditor(
                            controller: r,
                            targetId: targetId,
                            targetType: targetType,
                            ownerUserId: ownerUserId,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          );
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AverageHeader(r: r),

            const SizedBox(height: 16),

            if (user == null)
              const Text(
                "Inicia sesión para escribir una reseña.",
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 16),

            if (user != null &&
                !r.isOwner &&
                r.myReview == null &&
                !canWriteReview)
              Text(
                blockedMessage ?? "No puedes escribir una reseña para este contenido.",
                style: const TextStyle(color: Colors.grey),
              ),

            if (user != null && !r.isOwner && r.myReview == null && canWriteReview)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review),
                  label: const Text("Escribir una reseña"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    r.prepareNewReview();

                    final updated = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ReviewEditor(
                        controller: r,
                        targetId: targetId,
                        targetType: targetType,
                        ownerUserId: ownerUserId,
                      ),
                    );

                    if (updated == true) {
                      await r.load(
                        targetId: targetId,
                        targetType: targetType,
                        ownerUserId: ownerUserId,
                      );
                    }
                  },
                ),
              ),

            const SizedBox(height: 16),

            if (r.loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (r.reviews.isEmpty)
              const AppEmptyState(
                icon: Icons.reviews_outlined,
                title: 'Sin reseñas aún',
                subtitle: 'Cuando alguien comparta su experiencia, aparecerá aquí.',
                iconColor: AppColors.darkBlue,
              )
            else
              ...reviewWidgets,
          ],
        );
      },
    );
  }
}

class _AverageHeader extends StatelessWidget {
  final ReviewsController r;

  const _AverageHeader({required this.r});

  @override
  Widget build(BuildContext context) {
    final countText =
        '${r.totalReviews} ${r.totalReviews == 1 ? 'opinión' : 'opiniones'}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              r.averageRating.toStringAsFixed(1),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            ReviewStars(
              rating: r.averageRating,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          countText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
