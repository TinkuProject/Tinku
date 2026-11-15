import 'package:flutter/material.dart';
import '../../controllers/nearby/nearby_controller.dart';
import '../../core/enums.dart';
import '../../models/nearby_item_model.dart';
import '../../ui/themes/colors.dart';
import 'nearby_radius_selector.dart';
import '../../extensions/visit_entity_extension.dart';

class NearbySection extends StatelessWidget {
  final NearbyController controller;
  final void Function(NearbyItemModel item) onTapItem;

  const NearbySection({
    super.key,
    required this.controller,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final isTablet = width > 600;
            final itemWidth = isTablet ? 220.0 : 180.0;
            final height = isTablet ? 260.0 : 230.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 FILTRO SIEMPRE VISIBLE
                NearbyRadiusSelector(
                  selected: controller.radius,
                  onSelected: controller.setRadius,
                ),

                const SizedBox(height: 12),

                /// 🔹 LOADING
                if (controller.loading)
                  SizedBox(
                    height: height,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )

                /// 🔹 ERROR
                else if (controller.error != null)
                  SizedBox(
                    height: height,
                    child: const Center(
                      child: Text(
                        'Error al cargar cercanos',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )

                /// 🔹 EMPTY
                else if (controller.items.isEmpty)
                    SizedBox(
                      height: height,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'No hay lugares dentro de este rango.\nPrueba aumentando la distancia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )

                  /// 🔹 LIST
                  else
                    SizedBox(
                      height: height,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.items.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = controller.items[index];

                          return _NearbyCard(
                            item: item,
                            width: itemWidth,
                            onTap: () => onTapItem(item),
                          );
                        },
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final NearbyItemModel item;
  final double width;
  final VoidCallback onTap;

  const _NearbyCard({
    required this.item,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _getIcon(item.entityType),
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  item.entityType.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDistance(item.distance),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = item.imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 76,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _fallbackImage();
          },
        ),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported),
    );
  }

  IconData _getIcon(VisitEntity type) {
    switch (type) {
      case VisitEntity.business:
        return Icons.storefront;
      case VisitEntity.tourist_place:
        return Icons.place;
      case VisitEntity.event:
        return Icons.event;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}