import 'package:flutter/material.dart';

import '../../helpers/price_level_helper.dart';
import '../../models/business_model.dart';
import '../../ui/themes/colors.dart';
import '../common/network_image_with_loader.dart';

class BusinessCardCompact extends StatelessWidget {
  final BusinessModel business;
  final String? imageUrl;
  final double? rating;
  final double? price;
  final String? category;
  final VoidCallback? onTap;

  const BusinessCardCompact({
    super.key,
    required this.business,
    this.imageUrl,
    this.rating,
    this.price,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratingLabel = rating == null ? "Sin reseñas" : rating!.toStringAsFixed(1);
    final priceLabel = PriceLevelHelper.label(price);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 100,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            children: [

              /// ACENTO
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),

              /// 🖼️ IMAGEN
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(0),
                ),
                child: NetworkImageWithLoader(
                  imageUrl: imageUrl,
                  width: 90,
                  height: double.infinity,
                ),
              ),

              /// 📦 CONTENIDO
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 🔥 NOMBRE MÁS FUERTE
                      Text(
                        business.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// 🏷️ CATEGORÍA
                      if (category != null)
                        Text(
                          category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),

                      const Spacer(),

                      /// ⭐ + 💰
                      Row(
                        children: [

                          /// ⭐ badge
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      ratingLabel,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          if (priceLabel.isNotEmpty)
                            Semantics(
                              label: PriceLevelHelper.description(price),
                              child: Text(
                                priceLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔥 ICONO ACCIÓN (pequeño detalle que suma)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
