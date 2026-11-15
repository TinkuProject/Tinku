import 'package:flutter/material.dart';
import '../../../models/business_model.dart';

class EventOrganizer extends StatelessWidget {
  final BusinessModel? business;
  final dynamic organizer;

  const EventOrganizer({
    super.key,
    this.business,
    this.organizer,
  });

  @override
  Widget build(BuildContext context) {
    if (business == null && organizer == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Column(
        children: [
          const Text(
            "Organizado por",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  business != null ? Icons.store : Icons.person,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  business?.name ?? organizer?.username ?? "",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
