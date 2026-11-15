import 'package:flutter/material.dart';

import '../../../../models/product_model.dart';
import '../../../../controllers/product/product_carousel_controller.dart';
import '../../../product/product_carousel_mini_list.dart';

class BusinessProductsSection extends StatelessWidget {
  final List<ProductModel> products;
  final ProductCarouselController controller;
  final bool isService;

  const BusinessProductsSection({
    super.key,
    required this.products,
    required this.controller,
    required this.isService,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isService ? "Servicios" : "Productos",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        ProductCarouselMiniList(
          products: products,
          controller: controller,
        ),
      ],
    );
  }
}