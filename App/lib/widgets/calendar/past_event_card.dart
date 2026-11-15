import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../common/network_image_with_loader.dart';

class PastEventCard extends StatelessWidget {
  final EventModel event;
  final String? imageUrl;
  final bool isMulti;
  final String currentUserId;
  final VoidCallback onTap;

  const PastEventCard({
    super.key,
    required this.event,
    required this.imageUrl,
    required this.isMulti,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start =
    DateFormat('dd MMM yyyy – HH:mm', 'es').format(event.startDate);
    final end =
    DateFormat('dd MMM yyyy – HH:mm', 'es').format(event.endDate);

    final range = isMulti ? '$start → $end' : start;

    final isOrganizer = event.creatorId == currentUserId;

    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: NetworkImageWithLoader(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 110,
                ),
              ),

              Flexible(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOrganizer
                              ? Colors.blue.withValues(alpha: .12)
                              : Colors.green.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isOrganizer ? "Organizador" : "Reserva",
                          style: TextStyle(
                            color:
                            isOrganizer ? Colors.blue : Colors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isOrganizer
                                ? Colors.blue
                                : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              range,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
