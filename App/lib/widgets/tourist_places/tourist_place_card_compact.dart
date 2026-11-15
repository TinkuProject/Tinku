import 'package:flutter/material.dart';

import '../../models/tourist_place_model.dart';
import '../../ui/themes/colors.dart';
import '../common/network_image_with_loader.dart';

class TouristPlaceCardCompact extends StatelessWidget {
  final TouristPlaceModel place;
  final String? imageUrl;
  final VoidCallback? onTap;

  const TouristPlaceCardCompact({
    super.key,
    required this.place,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

              /// 🔥 ACENTO (verde para diferenciar)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),

              /// 🖼️ IMAGEN
              ClipRRect(
                borderRadius: BorderRadius.zero,
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

                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Lugar turístico",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const Spacer(),

                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "Ver ubicación",
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}