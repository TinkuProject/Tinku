import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class TypeTabSelector<T> extends StatelessWidget {
  final List<T> types;
  final T selectedType;
  final ValueChanged<T> onTypeSelected;

  /// Función para obtener el label visible
  final String Function(T type) getLabel;

  const TypeTabSelector({
    super.key,
    required this.types,
    required this.selectedType,
    required this.onTypeSelected,
    required this.getLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = type == selectedType;

          final color = isSelected ? AppColors.darkBlue : Colors.grey.shade700;

          final fontWeight = isSelected ? FontWeight.w600 : FontWeight.w400;

          return Semantics(
            button: true,
            selected: isSelected,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTypeSelected(type),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppColors.darkBlue
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    getLabel(type),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fontWeight,
                      color: color,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
