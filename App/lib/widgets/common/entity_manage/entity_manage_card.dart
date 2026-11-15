import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';

import 'entity_manage_actions.dart';
import 'entity_manage_header.dart';
import 'entity_manage_image.dart';
import 'entity_manage_info.dart';
import 'entity_manage_metrics.dart';

class EntityManageCard extends StatelessWidget {
  final String title;

  final String? category;
  final String? location;
  final String? organizer;

  final String imageUrl;

  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String? statusSubtitle;

  final int? views;
  final double? rating;
  final String? date;

  /// 🔹 contenido custom extra
  final Widget? extraContent;

  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EntityManageCard({
    super.key,
    required this.title,
    this.category,
    this.location,
    this.organizer,
    required this.imageUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    this.statusSubtitle,
    this.views,
    this.rating,
    this.date,
    this.extraContent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  bool get _showDivider =>
      extraContent != null ||
      views != null ||
      rating != null ||
      date != null ||
      onEdit != null ||
      onDelete != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TOP
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stackHeader =
                    constraints.maxWidth < 300 || textScale > 1.4;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntityManageHeader(
                      title: title,
                      statusLabel: statusLabel,
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      subtitle: statusSubtitle,
                    ),
                    if (category != null ||
                        location != null ||
                        organizer != null) ...[
                      const SizedBox(height: 6),
                      EntityManageInfo(
                        category: category,
                        location: location,
                        organizer: organizer,
                      ),
                    ],
                  ],
                );

                if (stackHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntityManageImage(imageUrl: imageUrl),
                      const SizedBox(height: 12),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntityManageImage(imageUrl: imageUrl),
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                );
              },
            ),

            /// 🔹 EXTRA CONTENT
            if (extraContent != null) ...[
              const SizedBox(height: 12),
              extraContent!,
            ],

            /// 🔹 DIVIDER
            if (_showDivider)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 1,
                color: Colors.grey.withValues(alpha: 0.2),
              ),

            /// 🔹 METRICS
            if (views != null || rating != null || date != null)
              EntityManageMetrics(
                views: views,
                rating: rating,
                date: date,
              ),

            /// 🔹 ACTIONS
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(height: 12),
              EntityManageActions(
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
