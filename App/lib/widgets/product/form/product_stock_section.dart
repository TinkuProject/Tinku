import 'package:flutter/material.dart';

import '../../../controllers/product/product_form_controller.dart';
import '../../common/form/app_text_field.dart';

class ProductStockSection extends StatelessWidget {
  final ProductFormController c;

  const ProductStockSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: "Cantidad disponible (opcional)",
      controller: c.stockCtrl,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        final val = int.tryParse(v);
        if (val == null || val < 0) return "Cantidad inválida";
        return null;
      },
    );
  }
}