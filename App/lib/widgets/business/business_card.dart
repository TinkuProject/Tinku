import 'package:flutter/material.dart';

import '../../helpers/price_level_helper.dart';
import '../../models/business_model.dart';
import '../../ui/themes/colors.dart';
import '../common/overlay_chip.dart';
import '../common/network_image_with_loader.dart';

class BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final String? imageUrl;
  final double? rating;
  final double? price;
  final String? category;
  final VoidCallback? onTap;

  const BusinessCard({
    super.key,
    required this.business,
    this.imageUrl,
    this.rating,
    this.price,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceLabel = PriceLevelHelper.label(price);
    final ratingLabel = rating == null ? "Sin reseñas" : rating!.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            /// IMAGE
            Positioned.fill(
              child: NetworkImageWithLoader(
                imageUrl: imageUrl,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            /// OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.textPrimary.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            /// CATEGORY
            if (category != null)
              Positioned(
                top: 12,
                left: 12,
                child: OverlayChip(
                  icon: Icons.category,
                  text: category!,
                ),
              ),

            /// RATING
            Positioned(
              top: 12,
              right: 12,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 116),
                child: OverlayChip(
                  icon: Icons.star_rounded,
                  text: ratingLabel,
                ),
              ),
            ),

            /// INFO
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      business.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  if (priceLabel.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Semantics(
                        label: PriceLevelHelper.description(price),
                        child: Text(
                          priceLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// TAP
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor:
                  Colors.white.withValues(alpha: 0.2),
                  highlightColor:
                  Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
