import 'package:flutter/material.dart';
import '../../controllers/event/my_calendar_controller.dart';

class CalendarEmptyStates extends StatelessWidget {
  final MyCalendarController controller;
  final List eventsForSelected;
  final bool hasUpcomingEvent;

  const CalendarEmptyStates({
    super.key,
    required this.controller,
    required this.eventsForSelected,
    this.hasUpcomingEvent = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyEvents = controller.all.isNotEmpty;

    final hasEventsThisMonth = controller.all.any((e) {
      final start = e.startDate;
      final end = e.endDate;

      final monthStart =
          DateTime(controller.focusedDay.year, controller.focusedDay.month, 1);
      final monthEnd = DateTime(
          controller.focusedDay.year, controller.focusedDay.month + 1, 0);

      return start.isBefore(monthEnd) && end.isAfter(monthStart);
    });

    if (controller.selectedDay == null && !hasAnyEvents) {
      return const _EmptyState(
        icon: Icons.event_busy,
        title: "Todavía no tienes eventos en tu calendario.",
        subtitle: "Los eventos que organices o confirmes aparecerán aquí.",
      );
    }

    if (controller.selectedDay == null && !hasEventsThisMonth) {
      return _EmptyState(
        icon: Icons.calendar_month,
        title: "No tenés eventos en ${controller.monthYearEs()}",
        subtitle: "Podés desplazarte a otros meses o explorar nuevos eventos.",
      );
    }

    if (controller.selectedDay == null) {
      return const _SimpleText("Seleccioná un día para ver tus eventos.");
    }

    if (eventsForSelected.isEmpty) {
      return _SimpleText(hasUpcomingEvent
          ? "No hay eventos en este día."
          : "No hay eventos en este día ni próximos eventos.");
    }

    return const SizedBox.shrink();
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleText extends StatelessWidget {
  final String text;

  const _SimpleText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text)),
    );
  }
}
