import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class EventPriceBlock extends StatelessWidget {
  final int? price;

  const EventPriceBlock({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = price == null || price == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isFree
                  ? Colors.green.withValues(alpha: 0.12)
                  : AppColors.darkBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFree ? Icons.check_circle : Icons.monetization_on,
              size: 20,
              color: isFree ? Colors.green : AppColors.darkBlue,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Costo",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFree ? "Gratuito" : "$price Tinkus",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isFree ? Colors.green : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}