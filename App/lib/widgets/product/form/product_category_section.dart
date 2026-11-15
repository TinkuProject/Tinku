import 'package:flutter/material.dart';

import '../../../controllers/product/product_form_controller.dart';
import '../../common/form/app_dropdown_field.dart';

class ProductCategorySection extends StatelessWidget {
  final ProductFormController c;

  const ProductCategorySection({
    super.key,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      label: "Categoría *",
      value: c.categoryId.isEmpty ? null : c.categoryId,

      items: c.categories.entries.map((e) {
        return DropdownMenuItem<String>(
          value: e.key,
          child: Text(e.value),
        );
      }).toList(),

      onChanged: (v) => c.setCategory(v),

      validator: (v) {
        if (v == null || v.isEmpty) {
          return "Seleccione una categoría";
        }

        return null;
      },
    );
  }
}
