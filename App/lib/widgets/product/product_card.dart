import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../ui/themes/colors.dart';
import '../../controllers/product/product_carousel_controller.dart';
import '../../extensions/product_extension.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final ProductCarouselController controller;

  const ProductCard({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final images = controller.productImages[product.id] ?? [];
    final imgIndex = controller.imageIndex[product.id] ?? 0;
    final imgCount = images.length;

    final category =
        controller.categoryNames[product.categoryId] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =======================
          // IMÁGENES
          // =======================
          Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: images.isNotEmpty
                    ? PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) =>
                      controller.setImageIndex(product.id, i),
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    cacheWidth: 800,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) =>
                        _imageFallback(),
                  ),
                )
                    : _imageFallback(),
              ),

              if (imgCount > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${imgIndex + 1}/$imgCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // =======================
          // INFO
          // =======================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        color: AppColors.darkBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Divider(height: 18),

                    if ((product.description ?? '').isNotEmpty)
                      Text(
                        product.description!,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                    if (product.stock != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Cantidad disponible: ${product.stock}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// FALLBACK
// =======================

Widget _imageFallback() {
  return Container(
    color: AppColors.surfaceSoft,
    alignment: Alignment.center,
    child: Icon(
      Icons.image,
      size: 60,
      color: AppColors.textSecondary.withValues(alpha: 0.5),
    ),
  );
}