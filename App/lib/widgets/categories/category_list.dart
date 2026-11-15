import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/category/category_controller.dart';
import '../../models/category_model.dart';
import '../../core/enums.dart';
import 'category_card.dart';

class CategoryList extends StatefulWidget {
  final CategoryEntityType selectedType;
  final void Function(CategoryModel) onCategoryTap;

  const CategoryList({
    super.key,
    required this.selectedType,
    required this.onCategoryTap,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<CategoryController>().load(widget.selectedType);
    });
  }

  @override
  void didUpdateWidget(covariant CategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedType != widget.selectedType) {
      context.read<CategoryController>().load(widget.selectedType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CategoryController>();

    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.categories.isEmpty) {
      return const Center(
        child: Text('No hay categorías disponibles.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: controller.categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final category = controller.categories[index];

        return CategoryCard(
          category: category,
          onTap: () => widget.onCategoryTap(category),
        );
      },
    );
  }
}