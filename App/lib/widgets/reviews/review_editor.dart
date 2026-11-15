import 'dart:io';

import 'package:flutter/material.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../controllers/shared/review/reviews_controller.dart';
import '../../helpers/media_helper.dart';
import '../../ui/themes/colors.dart';
import 'review_stars.dart';

class ReviewEditor extends StatelessWidget {
  final ReviewsController controller;
  final int targetId;
  final ReviewEntityType targetType;
  final String ownerUserId;

  const ReviewEditor({
    super.key,
    required this.controller,
    required this.targetId,
    required this.targetType,
    required this.ownerUserId,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final r = controller;
        final imageUrl =
        MediaHelper.getPrimaryUrl(r.myReview?.media ?? []);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TITLE
              Text(
                r.myReview == null
                    ? "Escribir reseña"
                    : "Editar reseña",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// IMAGE PICKER
              GestureDetector(
                onTap: r.pickImage,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surfaceSoft,
                  backgroundImage: r.pickedImage != null
                      ? FileImage(File(r.pickedImage!.path))
                      : (imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null) as ImageProvider?,
                  child: r.pickedImage == null && imageUrl == null
                      ? const Icon(Icons.add_a_photo)
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              /// STARS
              ReviewStars(
                rating: r.rating.toDouble(),
                size: 28,
                onTap: r.setRating,
              ),

              const SizedBox(height: 12),

              /// COMMENT
              TextField(
                controller: r.commentCtrl,
                decoration: const InputDecoration(
                  hintText: "Cuéntanos tu experiencia...",
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              /// SUBMIT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: r.submitting
                      ? null
                      : () async {
                    final res = await r.submit(
                      targetId: targetId,
                      targetType: targetType,
                      ownerUserId: ownerUserId,
                    );

                    if (!context.mounted) return;

                    if (res.ok) Navigator.pop(context, true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      tinkuSnackBar(res.message, isError: !res.ok),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: r.submitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Guardar reseña"),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
