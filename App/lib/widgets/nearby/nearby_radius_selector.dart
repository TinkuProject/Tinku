import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class NearbyRadiusSelector extends StatelessWidget {
  final double selected;
  final Function(double) onSelected;

  const NearbyRadiusSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      500.0,
      1000.0,
      5000.0,
      10000.0,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = options[i];
          final isSelected = r == selected;

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Radio ${_format(r)}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(r),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _format(r),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _format(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toInt()} km';
  }
}
