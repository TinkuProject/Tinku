import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';

class EntityManageInfo extends StatelessWidget {
  final String? category;
  final String? location;
  final String? organizer;

  const EntityManageInfo({
    super.key,
    this.category,
    this.location,
    this.organizer,
  });

  @override
  Widget build(BuildContext context) {
    final hasCategory = category != null && category!.trim().isNotEmpty;

    final hasLocation = location != null && location!.trim().isNotEmpty;

    final hasOrganizer = organizer != null && organizer!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// CATEGORY
        if (hasCategory)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_activity,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    category!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        /// ORGANIZER
        if (hasOrganizer) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.store,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  organizer!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        /// LOCATION
        if (hasLocation) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
