import 'package:flutter/material.dart';

import '../filters/filter_chip.dart';
import '../filters/filter_bottom_sheet.dart';

class FilterBarProducts extends StatelessWidget {
  final int order;
  final int? business;
  final Map<int, String>? businessItems;

  final ValueChanged<int> onOrder;
  final ValueChanged<int>? onBusiness;

  const FilterBarProducts({
    super.key,
    required this.order,
    required this.onOrder,
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
            icon: Icons.swap_vert,
            label: "Orden",
            value: {
              0: "Más recientes",
              1: "Más antiguos",
            }[order]!,
            onTap: () => openFilter(
              context,
              "Ordenar por",
              const {
                0: "Más recientes",
                1: "Más antiguos",
              },
              order,
              onOrder,
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