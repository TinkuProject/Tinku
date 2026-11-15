import 'package:flutter/material.dart';

import '../../../controllers/product/product_form_controller.dart';
import '../../common/form/app_text_field.dart';

class ProductPricingSection extends StatelessWidget {
  final ProductFormController c;

  const ProductPricingSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: "Precio (opcional)",
          controller: c.priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null || val < 0) return "Precio inválido";
            return null;
          },
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: "Precio Tinku (opcional)",
          controller: c.tinkuPriceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null || val < 0) return "Valor inválido";
            return null;
          },
        ),
      ],
    );
  }
}