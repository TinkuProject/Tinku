import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../ui/themes/colors.dart';
import '../../controllers/event/my_calendar_controller.dart';

class CalendarHeader extends StatelessWidget {
  final MyCalendarController controller;

  const CalendarHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            controller.monthYearEs(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkBlue,
            ),
          ),
          const Spacer(),
          SegmentedButton<CalendarFormat>(
            style: ButtonStyle(
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                const EdgeInsets.symmetric(horizontal: 8),
              ),
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                value: CalendarFormat.month,
                label: Text('Mes'),
              ),
              ButtonSegment(
                value: CalendarFormat.week,
                label: Text('Semana'),
              ),
            ],
            selected: {controller.format},
            onSelectionChanged: (s) => controller.setFormat(s.first),
          ),
        ],
      ),
    );
  }
}