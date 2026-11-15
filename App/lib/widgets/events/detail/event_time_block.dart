import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../ui/themes/colors.dart';

class EventTimeBlock extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const EventTimeBlock({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final sameDay =
        start.day == end.day &&
            start.month == end.month &&
            start.year == end.year;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          /// ICONO
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.darkBlue,
            ),
          ),

          const SizedBox(width: 12),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fecha y hora",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                if (sameDay) ...[
                  Text(
                    DateFormat('EEEE, dd MMM').format(start),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    DateFormat('dd MMM • HH:mm').format(start),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Hasta ${DateFormat('dd MMM • HH:mm').format(end)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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