import 'package:flutter/material.dart';

import '../../../controllers/product/product_form_controller.dart';
import '../../common/form/app_dropdown_field.dart';

class ProductVolumeSection extends StatelessWidget {
  const ProductVolumeSection({super.key, required this.c});

  final ProductFormController c;

  static const _options = {
    'small': 'Pequeño',
    'medium': 'Mediano',
    'large': 'Grande',
  };

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      label: 'Volumen para retiro *',
      value: c.volumeTier,
      items: _options.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: c.setVolumeTier,
      validator: (value) {
        if (value == null || !_options.containsKey(value)) {
          return 'Seleccione el volumen';
        }
        return null;
      },
    );
  }
}
