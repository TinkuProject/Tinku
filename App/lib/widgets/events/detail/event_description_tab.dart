import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../../../ui/themes/colors.dart';
import 'event_time_block.dart';
import 'event_capacity_block.dart';
import 'event_price_block.dart';
import 'attend_section.dart';

class EventDescriptionTab extends StatelessWidget {
  final EventModel event;
  final dynamic controller;

  const EventDescriptionTab({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          "Descripción del evento",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            (event.description ?? '').isNotEmpty
                ? event.description!
                : "Sin descripción disponible.",
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Detalles del evento",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 12),
        EventTimeBlock(
          start: event.startDate,
          end: event.endDate,
        ),
        const SizedBox(height: 12),
        EventCapacityBlock(
          capacity: event.capacity,
          confirmed: controller.confirmedReservations,
        ),
        const SizedBox(height: 12),
        EventPriceBlock(
          price: event.tinkuPrice,
        ),
        const SizedBox(height: 16),
        if (!controller.canManageEvent)
          AttendSection(controller: controller),
      ],
    );
  }
}
