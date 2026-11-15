import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../controllers/event/my_calendar_controller.dart';
import '../../models/event_model.dart';
import '../../ui/themes/colors.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

class CalendarWidget extends StatelessWidget {
  final MyCalendarController controller;

  const CalendarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TableCalendar<EventModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: controller.focusedDay,
            calendarFormat: controller.format,
            selectedDayPredicate: (day) =>
                isSameDay(controller.selectedDay, day),
            onFormatChanged: controller.setFormat,
            onDaySelected: controller.onDaySelected,
            onPageChanged: controller.onPageChanged,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextFormatter: (date, locale) =>
                  DateFormat('MMMM y', 'es').format(date),
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.darkBlue,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.mediumBlue.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.darkBlue,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: controller.eventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                final userId =
                    context.read<UserProvider>().user!.id;

                final hasOrganizer =
                events.any((e) => e.creatorId == userId);
                final hasReservation =
                events.any((e) => e.creatorId != userId);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasOrganizer)
                      _dot(Colors.blue),
                    if (hasReservation)
                      _dot(Colors.green),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}