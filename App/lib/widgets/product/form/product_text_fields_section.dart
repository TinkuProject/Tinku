import 'package:flutter/material.dart';

import '../../../controllers/product/product_form_controller.dart';
import '../../common/form/app_text_field.dart';

class ProductTextFieldsSection extends StatelessWidget {
  final ProductFormController c;

  const ProductTextFieldsSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: "Nombre *",
          controller: c.nameCtrl,
          validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: "Descripción (opcional)",
          controller: c.descCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}
