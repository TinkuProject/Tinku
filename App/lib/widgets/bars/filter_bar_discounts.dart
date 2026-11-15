import 'package:flutter/material.dart';

import '../filters/filter_bottom_sheet.dart';
import '../filters/filter_chip.dart';

class FilterBarDiscounts extends StatelessWidget {
  final int order;
  final int business;
  final Map<int, String> businessItems;
  final ValueChanged<int> onOrder;
  final ValueChanged<int> onBusiness;

  const FilterBarDiscounts({
    super.key,
    required this.order,
    required this.business,
    required this.businessItems,
    required this.onOrder,
    required this.onBusiness,
  });

  @override
  Widget build(BuildContext context) {
    const orderItems = {
      0: 'Más recientes',
      1: 'Mayor descuento',
      2: 'Menor descuento',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipWidget(
            icon: Icons.store,
            label: 'Negocio',
            value: businessItems[business] ?? 'Todos',
            onTap: () => openFilter(
              context,
              'Negocio',
              businessItems,
              business,
              onBusiness,
            ),
          ),
          const SizedBox(width: 8),
          FilterChipWidget(
            icon: Icons.swap_vert,
            label: 'Orden',
            value: orderItems[order] ?? orderItems[0]!,
            onTap: () => openFilter(
              context,
              'Ordenar por',
              orderItems,
              order,
              onOrder,
            ),
          ),
        ],
      ),
    );
  }
}
