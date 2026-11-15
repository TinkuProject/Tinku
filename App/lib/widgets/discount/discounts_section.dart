import 'package:flutter/material.dart';

import '../../controllers/discount/discount_controller.dart';
import '../../models/discount_model.dart';
import '../../ui/themes/colors.dart';

import '../common/empty/app_empty.dart';
import 'discount_carousel.dart';

class DiscountsSection extends StatelessWidget {
  final DiscountController controller;
  final PageController pageController;
  final ValueChanged<DiscountModel> onTap;

  const DiscountsSection({
    super.key,
    required this.controller,
    required this.pageController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        /// 🔄 LOADING
        if (controller.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final discounts = controller.activeValid;

        /// 📭 EMPTY
        if (discounts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppEmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No hay descuentos activos',
              subtitle: 'Pronto aparecerán nuevas ofertas disponibles.',
            ),
          );
        }

        /// 🎯 CONTENT
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.mustard,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Descuentos activos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 SUBTITLE
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 4,
              ),
              child: Text(
                'Ofertas disponibles por tiempo limitado.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),

            const SizedBox(height: 8),

            /// 🎠 CAROUSEL
            DiscountsCarousel(
              discounts: discounts,
              controller: pageController,
              discountController: controller,
              onTap: onTap,
            ),
          ],
        );
      },
    );
  }
}
