import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  final Color? iconColor;
  final Color? backgroundColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isTablet = width > 600;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackContent = width < 340 || textScale > 1.4;

        final iconSize = isTablet ? 48.0 : 40.0;
        final titleSize = isTablet ? 16.0 : 14.0;
        final padding = isTablet ? 20.0 : 16.0;

        final resolvedColor = iconColor ?? AppColors.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Flex(
              direction: stackContent ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 🔹 ICON
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: resolvedColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: resolvedColor,
                  ),
                ),

                SizedBox(
                  width: stackContent ? 0 : 14,
                  height: stackContent ? 12 : 0,
                ),

                /// 🔹 TEXT
                Flexible(
                  child: Column(
                    crossAxisAlignment: stackContent
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign:
                            stackContent ? TextAlign.center : TextAlign.start,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign:
                            stackContent ? TextAlign.center : TextAlign.start,
                        style: TextStyle(
                          fontSize: titleSize - 1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
