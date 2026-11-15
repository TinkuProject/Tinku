import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class EventCapacityBlock extends StatelessWidget {
  final int? capacity;
  final int confirmed;

  const EventCapacityBlock({
    super.key,
    required this.capacity,
    required this.confirmed,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = capacity != null && capacity! > 0;
    final remaining = hasLimit ? capacity! - confirmed : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people,
              size: 20,
              color: AppColors.darkBlue,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cupo",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                if (!hasLimit)
                  const Text(
                    "Sin límite",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else ...[
                  Text(
                    "$confirmed / $capacity asistentes",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: confirmed / capacity!,
                      minHeight: 6,
                    ),
                  ),

                  if (remaining != null && remaining <= 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "🔥 Últimos $remaining lugares",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}