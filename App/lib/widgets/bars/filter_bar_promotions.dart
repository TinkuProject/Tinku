import 'package:flutter/material.dart';

import '../filters/filter_chip.dart';
import '../filters/filter_bottom_sheet.dart';

class FilterBarPromotions extends StatelessWidget {
  final int discount;
  final int? business;
  final Map<int, String>? businessItems;

  final ValueChanged<int> onDiscount;
  final ValueChanged<int>? onBusiness;

  const FilterBarPromotions({
    super.key,
    required this.discount,
    required this.onDiscount,
    this.business,
    this.businessItems,
    this.onBusiness,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipWidget(
            icon: Icons.local_offer,
            label: "Descuento",
            value: {
              0: "Todos",
              1: "Mayor %",
              2: "Menor %",
            }[discount]!,
            onTap: () => openFilter(
              context,
              "Ordenar por descuento",
              const {
                0: "Todos",
                1: "Mayor %",
                2: "Menor %",
              },
              discount,
              onDiscount,
            ),
          ),

          if (businessItems != null &&
              business != null &&
              onBusiness != null) ...[
            const SizedBox(width: 8),
            FilterChipWidget(
              icon: Icons.store,
              label: "Negocio",
              value: businessItems![business] ?? "Todos",
              onTap: () => openFilter(
                context,
                "Negocio",
                businessItems!,
                business!,
                onBusiness!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}