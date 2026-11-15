import 'package:flutter/material.dart';
import '../../../controllers/business/business_form_controller.dart';
import '../../common/form/app_dropdown_field.dart';

class BusinessCategorySection extends StatelessWidget {
  final BusinessFormController c;

  const BusinessCategorySection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<int>(
      label: "Categoría *",
      value: c.selectedCategoryId,
      items: c.categories.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      validator: (v) => v == null ? "Seleccione una categoría" : null,
      onChanged: c.setCategory,
    );
  }
}
