import 'package:flutter/material.dart';

import '../../ui/themes/colors.dart';
import '../../controllers/shared/transport/entity_transport_controller.dart';
import '../common/empty/app_empty.dart';

class TransportChipSelector extends StatelessWidget {
  final Map<String, String> transportLines;
  final List<String> selectedLines;
  final EntityTransportController controller;
  final Color Function(String lineId)? lineColor;

  const TransportChipSelector({
    super.key,
    required this.transportLines,
    required this.selectedLines,
    required this.controller,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (transportLines.isEmpty) {
      return const AppEmptyState(
        icon: Icons.directions_bus_filled_outlined,
        title: 'Sin líneas cercanas',
        subtitle: 'Aún no encontramos recorridos de transporte asociados.',
        iconColor: AppColors.darkBlue,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: transportLines.entries.map((entry) {
        final id = entry.key;
        final name = entry.value;

        final isSelected = selectedLines.contains(id);
        final color = lineColor?.call(id) ?? AppColors.darkBlue;

        return FilterChip(
          label: Text(name),
          selected: isSelected,
          selectedColor: color,
          backgroundColor: color.withValues(alpha: 0.08),
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.textPrimary,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          onSelected: (_) => controller.toggleLine(id),
        );
      }).toList(),
    );
  }
}
