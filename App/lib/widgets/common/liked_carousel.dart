import 'package:flutter/material.dart';

import '../../models/business_model.dart';
import '../../models/event_model.dart';
import '../../models/user_visit_model.dart';
import '../../ui/themes/colors.dart';

// =========================
// TYPES
// =========================

enum LikedType { business, event }

class LikedItem {
  final LikedType type;
  final UserVisitModel visit;

  final BusinessModel? business;
  final EventModel? event;

  final String title;
  final String subtitle;
  final String category;
  final List<String> images;

  const LikedItem({
    required this.type,
    required this.visit,
    this.business,
    this.event,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.images,
  }) : assert(
  (type == LikedType.business && business != null && event == null) ||
      (type == LikedType.event && event != null && business == null),
  );
}

// =========================
// CAROUSEL
// =========================

class LikedCarousel extends StatelessWidget {
  final List<LikedItem> items;
  final PageController controller;
  final void Function(UserVisitModel visit) onRemove;
  final void Function(LikedItem item) onTap;

  const LikedCarousel({
    super.key,
    required this.items,
    required this.controller,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: controller,
        padEnds: false,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _LikedCard(
              item: item,
              onRemove: onRemove,
              onTap: onTap,
            ),
          );
        },
      ),
    );
  }
}

// =========================
// CARD
// =========================

class _LikedCard extends StatelessWidget {
  final LikedItem item;
  final void Function(UserVisitModel visit) onRemove;
  final void Function(LikedItem item) onTap;

  const _LikedCard({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = item.images.isNotEmpty ? item.images.first : null;

    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onTap(item),
        child: Stack(
          children: [
            /// 🖼️ IMAGEN
            Positioned.fill(
              child: image != null
                  ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
                  : _fallback(),
            ),

            /// 🌑 OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.textPrimary.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            /// 🏷️ CATEGORÍA
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            /// ❤️ FAVORITO
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: AppColors.surface.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => onRemove(item.visit),
                ),
              ),
            ),

            /// 📍 CONTENIDO
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                          Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.type == LikedType.business
                              ? 'Negocio'
                              : 'Evento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// FALLBACK
// =========================

Widget _fallback() {
  return Container(
    color: AppColors.surfaceSoft,
    child: Center(
      child: Icon(
        Icons.image,
        size: 40,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    ),
  );
}