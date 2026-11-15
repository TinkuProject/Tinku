import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../ui/themes/colors.dart';

class CategoryChipSelector extends StatelessWidget {
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategorySelected;

  const CategoryChipSelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategoryId == cat.id;

          return ChoiceChip(
            label: Text(
              cat.name,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.darkBlue,
            backgroundColor: AppColors.surfaceSoft,
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected
                    ? AppColors.darkBlue
                    : AppColors.border,
                width: 1.2,
              ),
            ),
            onSelected: (_) => onCategorySelected(cat.id),
          );
        },
      ),
    );
  }
}