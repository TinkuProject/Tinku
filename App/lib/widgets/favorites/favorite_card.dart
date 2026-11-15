import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../ui/themes/colors.dart';

class FavoriteCard extends StatelessWidget {
  final VisitEntity type;
  final String title;
  final String subtitle;
  final String category;
  final List<String> images;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoriteCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.images,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CAROUSEL
          _ImageCarousel(
            images: images,
            onTap: onTap,
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),

          /// CHIPS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Chip(
                  label: Text(category, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.mustard,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _getTypeLabel(type),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.surfaceSoft,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// TYPE LABEL
  /// =========================
  String _getTypeLabel(VisitEntity type) {
    switch (type) {
      case VisitEntity.business:
        return 'Negocio';
      case VisitEntity.event:
        return 'Evento';
      case VisitEntity.tourist_place:
        return 'Lugar turístico';
    }
  }
}

/// =========================
/// CAROUSEL SEPARADO
/// =========================
class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final VoidCallback onTap;

  const _ImageCarousel({
    required this.images,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imgs = images.isNotEmpty ? images : [null];

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: imgs.length,
        itemBuilder: (_, index) {
          final url = imgs[index];

          return InkWell(
            onTap: onTap,
            child: url != null
                ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        size: 40,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }
}