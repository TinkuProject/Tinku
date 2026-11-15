import 'package:flutter/material.dart';

import '../../ui/themes/colors.dart';

class BusinessFilterSelect extends StatelessWidget {
  const BusinessFilterSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label = 'Negocio',
    this.disabledIds = const {},
    this.disabledLabel = 'Pendiente',
  });

  final int value;
  final Map<int, String> items;
  final ValueChanged<int> onChanged;
  final String label;
  final Set<int> disabledIds;
  final String disabledLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<int>(
      initialValue:
          items.containsKey(value) && !disabledIds.contains(value) ? value : 0,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.storefront_outlined,
          color: AppColors.darkBlue,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<int>(
              value: entry.key,
              enabled: !disabledIds.contains(entry.key),
              child: Opacity(
                opacity: disabledIds.contains(entry.key) ? 0.45 : 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (disabledIds.contains(entry.key)) ...[
                      const SizedBox(width: 8),
                      Text(
                        disabledLabel,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
