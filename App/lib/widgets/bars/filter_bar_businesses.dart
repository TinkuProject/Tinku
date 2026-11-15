import 'package:flutter/material.dart';

import '../filters/filter_chip.dart';
import '../filters/filter_bottom_sheet.dart';

class FilterBarBusinesses extends StatelessWidget {
  final String status;
  final String order;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onOrder;

  const FilterBarBusinesses({
    super.key,
    required this.status,
    required this.order,
    required this.onStatus,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipWidget(
            icon: Icons.filter_alt_outlined,
            label: "Estado",
            value: {
              "todos": "Todos",
              "activo": "Activos",
              "pendiente": "Pendientes",
              "rechazado": "Rechazados",
              "inactivo": "Inactivos",
            }[status]!,
            onTap: () => openFilter(
              context,
              "Estado",
              const {
                "todos": "Todos",
                "activo": "Activos",
                "pendiente": "Pendientes",
                "rechazado": "Rechazados",
                "inactivo": "Inactivos",
              },
              status,
              onStatus,
            ),
          ),

          const SizedBox(width: 8),

          FilterChipWidget(
            icon: Icons.swap_vert,
            label: "Orden",
            value: {
              "desc": "Más recientes",
              "asc": "Más antiguos",
            }[order]!,
            onTap: () => openFilter(
              context,
              "Ordenar por",
              const {
                "desc": "Más recientes",
                "asc": "Más antiguos",
              },
              order,
              onOrder,
            ),
          ),
        ],
      ),
    );
  }
}