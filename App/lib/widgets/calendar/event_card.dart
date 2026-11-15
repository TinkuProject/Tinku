import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool isMulti;
  final String? imageUrl;
  final String currentUserId;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isMulti,
    required this.imageUrl,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startDate = DateFormat('dd MMM yyyy', 'es').format(event.startDate);
    final startTime = DateFormat('HH:mm', 'es').format(event.startDate);
    final endDate = DateFormat('dd MMM yyyy', 'es').format(event.endDate);
    final endTime = DateFormat('HH:mm', 'es').format(event.endDate);

    final range = isMulti
        ? '$startDate $startTime → $endDate $endTime'
        : '$startDate $startTime a $endTime';

    final isOrganizer = event.creatorId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isOrganizer ? Colors.blue : Colors.green,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.event,
                      size: 36, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
                          isOrganizer ? "Organizador" : "Asistiendo",
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
                            ),
                          ),
                        ],
                      ),

                      const Row(
                        children: [
                          Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16),
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