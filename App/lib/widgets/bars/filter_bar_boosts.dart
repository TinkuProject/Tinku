import 'package:flutter/material.dart';

import '../filters/filter_bottom_sheet.dart';
import '../filters/filter_chip.dart';

class FilterBarBoosts extends StatelessWidget {
  final String status;
  final String order;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onOrder;

  const FilterBarBoosts({
    super.key,
    required this.status,
    required this.order,
    required this.onStatus,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    const statusItems = {
      'todos': 'Todos',
      'activo': 'Activos',
      'inactivo': 'Inactivos',
      'cancelado': 'Cancelados',
    };

    const orderItems = {
      'desc': 'Más recientes',
      'asc': 'Más antiguos',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipWidget(
            icon: Icons.filter_alt_outlined,
            label: 'Estado',
            value: statusItems[status] ?? statusItems['todos']!,
            onTap: () => openFilter(
              context,
              'Estado',
              statusItems,
              status,
              onStatus,
            ),
          ),
          const SizedBox(width: 8),
          FilterChipWidget(
            icon: Icons.swap_vert,
            label: 'Orden',
            value: orderItems[order] ?? orderItems['desc']!,
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
