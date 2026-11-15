import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class TouristPlaceHeader extends StatelessWidget {
  final String image;
  final String name;
  final String category;
  final bool isVisited;
  final VoidCallback onVisitedTap;

  const TouristPlaceHeader({
    super.key,
    required this.image,
    required this.name,
    required this.category,
    required this.isVisited,
    required this.onVisitedTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),

            /// Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.textPrimary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            /// TEXT
            Positioned(
              bottom: 20,
              left: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),

            /// BUTTON
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: AnimatedScale(
                scale: isVisited ? 1.2 : 1,
                duration: const Duration(milliseconds: 250),
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onVisitedTap,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        isVisited
                            ? Icons.check
                            : Icons.place_outlined,
                        color: isVisited
                            ? Colors.green
                            : AppColors.lightBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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