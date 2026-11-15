import 'package:flutter/material.dart';

import '../../controllers/discount/discount_controller.dart';
import '../../models/discount_model.dart';
import '../../ui/themes/colors.dart';

import '../../utils/date/date_formatter.dart';

import '../common/carousel/app_carousel.dart';

class DiscountsCarousel extends StatelessWidget {
  final List<DiscountModel> discounts;
  final PageController controller;
  final DiscountController discountController;
  final ValueChanged<DiscountModel> onTap;

  const DiscountsCarousel({
    super.key,
    required this.discounts,
    required this.controller,
    required this.discountController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (discounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCarousel(
      controller: controller,
      itemCount: discounts.length,
      height: 340,
      viewportFraction: 0.90,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final discount = discounts[index];

        final data = discountController.getCardData(discount.id);

        final businessName = (data?['businessName'] as String?) ?? 'Negocio';

        final imageUrl = data?['image'] as String?;

        final percentage = discount.discountPercent.toStringAsFixed(0);

        final dateRange = DateFormatter.simpleRange(
          discount.startDate,
          discount.endDate,
        );

        final now = DateTime.now();

        final remainingDays = discount.endDate.isBefore(now)
            ? 0
            : discount.endDate.difference(now).inDays;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onTap(discount),
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
                    /// 🔹 IMAGE
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return _fallback();
                              },
                            )
                          : _fallback(),
                    ),

                    /// 🔹 CONTENT
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// % DISCOUNT
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '-$percentage%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 18,
                                  color:
                                      AppColors.mustard.withValues(alpha: 0.9),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            /// BUSINESS NAME
                            Text(
                              businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// DESCRIPTION
                            if (discount.description != null &&
                                discount.description!.trim().isNotEmpty)
                              Text(
                                discount.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),

                            const Spacer(),

                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkBlue
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      dateRange,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  remainingDays > 0
                                      ? '$remainingDays días'
                                      : 'Último día',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: remainingDays <= 1
                                        ? Colors.red
                                        : Colors.grey,
                                    fontWeight: remainingDays <= 1
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

Widget _fallback() {
  return Container(
    height: 130,
    width: double.infinity,
    color: AppColors.mustard.withValues(alpha: 0.08),
    child: Center(
      child: Icon(
        Icons.local_offer_outlined,
        size: 56,
        color: AppColors.mustard.withValues(alpha: 0.8),
      ),
    ),
  );
}
