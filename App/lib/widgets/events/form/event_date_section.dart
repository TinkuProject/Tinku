import 'package:flutter/material.dart';
import '../../../utils/date/date_formatter.dart';
import '../../common/form/app_date_field.dart';

class EventDateSection extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const EventDateSection({
    super.key,
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          AppDateField(
            label: "Inicio",
            value: start == null ? null : DateFormatter.formDateTime(start!),
            onTap: onPickStart,
          ),

          const SizedBox(height: 12),

          AppDateField(
            label: "Fin",
            value: end == null ? null : DateFormatter.formDateTime(end!),
            onTap: onPickEnd,
          ),
        ],
    );
  }
}