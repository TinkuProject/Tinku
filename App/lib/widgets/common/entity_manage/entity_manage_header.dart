import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';
import 'entity_status_chip.dart';

class EntityManageHeader extends StatelessWidget {
  final String title;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String? subtitle;

  const EntityManageHeader({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackStatus = constraints.maxWidth < 230 || textScale > 1.35;

        final titleWidget = Text(
          title,
          maxLines: stackStatus ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        );
        final statusWidget = Align(
          alignment: Alignment.topRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              EntityStatusChip(
                label: statusLabel,
                color: statusColor,
                icon: statusIcon,
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );

        if (stackStatus) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 8),
              statusWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 10),
            statusWidget,
          ],
        );
      },
    );
  }
}
