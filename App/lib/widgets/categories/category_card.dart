import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../ui/themes/colors.dart';
import '../common/network_image_with_loader.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final String? imageUrl;
  final VoidCallback onTap;
  final double height;

  static const _radius = BorderRadius.all(Radius.circular(16));

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.imageUrl,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// IMAGE
            NetworkImageWithLoader(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
            ),

            /// OVERLAY
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.textPrimary.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            /// TEXT
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: textStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}