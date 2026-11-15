import 'package:flutter/material.dart';

import '../../models/tourist_place_model.dart';
import '../../ui/themes/colors.dart';

class TouristPlaceCarousel extends StatelessWidget {
  final List<TouristPlaceModel> places;
  final Map<int, String?> imageUrls;
  final PageController controller;

  final bool showExtraInfo;
  final void Function(TouristPlaceModel place)? onTap;
  final void Function(TouristPlaceModel place)? onRemove;

  const TouristPlaceCarousel({
    super.key,
    required this.places,
    required this.imageUrls,
    required this.controller,
    this.showExtraInfo = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: controller,
        padEnds: false,
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          final imageUrl = imageUrls[place.id];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: _Card(
              place: place,
              imageUrl: imageUrl,
              onTap: onTap,
              onRemove: onRemove,
              showExtraInfo: showExtraInfo,
            ),
          );
        },
      ),
    );
  }
}

/// =========================
/// CARD (separado)
/// =========================
class _Card extends StatelessWidget {
  final TouristPlaceModel place;
  final String? imageUrl;

  final void Function(TouristPlaceModel)? onTap;
  final void Function(TouristPlaceModel)? onRemove;
  final bool showExtraInfo;

  const _Card({
    required this.place,
    required this.imageUrl,
    required this.onTap,
    required this.onRemove,
    required this.showExtraInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(place),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              /// 🖼️ IMAGE
              Positioned.fill(
                child: Image.network(
                  imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                ),
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

              /// ❌ REMOVE / ACTION
              if (onRemove != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemove!(place),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.place,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

              /// 📍 TEXT CONTENT
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (showExtraInfo && place.description != null)
                      Text(
                        place.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
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
