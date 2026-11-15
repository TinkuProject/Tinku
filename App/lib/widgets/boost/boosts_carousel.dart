import 'package:flutter/material.dart';

import '../../controllers/boost/boost_controller.dart';
import '../../helpers/price_level_helper.dart';
import '../../models/boost_model.dart';
import '../../ui/themes/colors.dart';
import '../common/carousel/app_carousel.dart';

class BoostsCarousel extends StatelessWidget {
  final String? title;
  final List<BoostModel> boosts;
  final PageController controller;
  final BoostController boostController;
  final void Function(BuildContext, BoostModel) onTap;

  const BoostsCarousel({
    super.key,
    this.title,
    required this.boosts,
    required this.controller,
    required this.boostController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (boosts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

        AppCarousel(
          controller: controller,
          itemCount: boosts.length,
          height: 300,
          viewportFraction: 0.90,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemBuilder: (context, index) {
            final boost = boosts[index];

            final data = boostController.getCardData(boost.id);

            final name = (data?['title'] as String?) ?? 'Impulso';
            final imageUrl = data?['image'] as String?;
            final icon = data?['icon'] as IconData? ?? Icons.campaign;
            final description = (data?['subtitle'] as String?) ?? '';
            final price = data?['price'] as double?;
            final rating = data?['rating'] as double?;
            final priceLabel = PriceLevelHelper.label(price);
            final ratingLabel =
                rating == null ? "Sin reseñas" : rating.toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onTap(context, boost),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.white,
                          AppColors.surfaceSoft,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: imageUrl != null
                              ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 125,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallback(icon),
                          )
                              : _fallback(icon),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _RatingBadge(text: ratingLabel),
                                    if (priceLabel.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Semantics(
                                          label: PriceLevelHelper.description(price),
                                          child: Text(
                                            priceLabel,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Widget _fallback(IconData icon) {
  return Container(
    height: 125,
    width: double.infinity,
    color: AppColors.darkBlue.withValues(alpha: 0.08),
    child: Center(
      child: Icon(
        icon,
        size: 48,
        color: AppColors.darkBlue,
      ),
    ),
  );
}

class _RatingBadge extends StatelessWidget {
  final String text;

  const _RatingBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 13,
              color: Colors.amber,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
