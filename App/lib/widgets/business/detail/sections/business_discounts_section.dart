import 'package:flutter/material.dart';
import '../../../../models/discount_model.dart';

class BusinessDiscountsSection extends StatelessWidget {
  final List<DiscountModel> discounts;

  const BusinessDiscountsSection({
    super.key,
    required this.discounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Promociones activas",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        if (discounts.isEmpty)
          const Text(
            "Este negocio no cuenta con promociones activas.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          Column(
            children: discounts.map((d) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer,
                        color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${d.discountPercent}% de descuento",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}