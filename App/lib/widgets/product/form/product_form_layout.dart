import 'package:flutter/material.dart';

import '../../../controllers/product/product_form_controller.dart';
import '../../common/actions/submit_button.dart';
import '../../common/form/app_form_section.dart';
import '../../shared/media/media_hero.dart';
import '../../shared/media/media_picker_section.dart';
import 'product_category_section.dart';
import 'product_pricing_section.dart';
import 'product_stock_section.dart';
import 'product_text_fields_section.dart';
import 'product_volume_section.dart';

class ProductFormLayout extends StatelessWidget {
  final ProductFormController c;
  final GlobalKey<FormState> formKey;
  final Future<void> Function() onSubmit;

  const ProductFormLayout({
    super.key,
    required this.c,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          MediaHero(images: c.media.items),
          const SizedBox(height: 20),

          AppFormSection(
            title: "Información básica",
            child: Column(
              children: [
                ProductTextFieldsSection(c: c),
                const SizedBox(height: 12),
                ProductCategorySection(c: c),
              ],
            ),
          ),

          AppFormSection(
            title: "Precio y stock",
            child: Column(
              children: [
                ProductPricingSection(c: c),
                const SizedBox(height: 12),
                ProductStockSection(c: c),
                const SizedBox(height: 12),
                ProductVolumeSection(c: c),
              ],
            ),
          ),

          AppFormSection(
            title: "Imágenes",
            child: MediaPickerSection(
              images: c.media.items,
              onAdd: () => c.media.pickImagesFromGallery(context),
              onRemove: c.media.removeItem,
            ),
          ),

          const SizedBox(height: 30),

          SubmitButton(
            loading: c.loading,
            text: "Guardar producto",
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
