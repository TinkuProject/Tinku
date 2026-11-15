import 'package:flutter/material.dart';
import '../../components/utils.dart';
import '../../helpers/error_message_helper.dart';
import '../../utils/date/date_formatter.dart';
import '../../core/enums.dart';
import '../../controllers/shared/opening_hours/opening_hours_controller.dart';
import '../../core/constants.dart';
import '../../ui/themes/colors.dart';

class WeeklyHoursInput extends StatefulWidget {
  final OpeningHoursController controller;

  const WeeklyHoursInput({
    super.key,
    required this.controller,
  });

  @override
  State<WeeklyHoursInput> createState() => _WeeklyHoursInputState();
}

class _WeeklyHoursInputState extends State<WeeklyHoursInput> {
  final Map<WeekDay, bool> selectedDays = {
    WeekDay.monday: false,
    WeekDay.tuesday: false,
    WeekDay.wednesday: false,
    WeekDay.thursday: false,
    WeekDay.friday: false,
    WeekDay.saturday: false,
    WeekDay.sunday: false,
  };

  TimeOfDay? start;
  TimeOfDay? end;

  void _apply() {
    if (start == null || end == null) return;

    for (final entry in selectedDays.entries) {
      if (!entry.value) continue;

      try {
        widget.controller.addHour(
          day: entry.key,
          start: start!,
          end: end!,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          tinkuSnackBar(userFacingError(e), isError: true),
        );
        return;
      }
    }

    setState(() {
      for (final key in selectedDays.keys) {
        selectedDays[key] = false;
      }
      start = null;
      end = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = widget.controller.groupedHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =======================
        // ATAJOS
        // =======================
        const Text(
          "Atajos",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _shortcut("24h", () {
              setState(() {
                selectedDays.updateAll((key, value) => true);
                start = const TimeOfDay(hour: 0, minute: 0);
                end = const TimeOfDay(hour: 23, minute: 59);
              });
            }),
            _shortcut("Días hábiles", () {
              setState(() {
                selectedDays.updateAll((key, value) => false);
                for (final d in [
                  WeekDay.monday,
                  WeekDay.tuesday,
                  WeekDay.wednesday,
                  WeekDay.thursday,
                  WeekDay.friday,
                ]) {
                  selectedDays[d] = true;
                }
              });
            }),
            _shortcut("Fin de semana", () {
              setState(() {
                selectedDays.updateAll((key, value) => false);
                selectedDays[WeekDay.saturday] = true;
                selectedDays[WeekDay.sunday] = true;
              });
            }),
          ],
        ),

        const SizedBox(height: 20),

        // =======================
        // DÍAS
        // =======================
        const Text(
          "Días",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedDays.keys.map((day) {
            final selected = selectedDays[day]!;

            return GestureDetector(
              onTap: () => setState(() => selectedDays[day] = !selected),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.navyBlue
                      : AppColors.navyBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.navyBlue
                        : AppColors.navyBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  dayNamesEs[weekDayToString(day)] ??
                      weekDayToString(day),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // =======================
        // HORARIO
        // =======================
        Row(
          children: [
            Expanded(
              child: _timeBox(
                context,
                label: 'Apertura',
                value: start,
                onPick: (t) => setState(() => start = t),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _timeBox(
                context,
                label: 'Cierre',
                value: end,
                onPick: (t) => setState(() => end = t),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // =======================
        // BOTÓN
        // =======================
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Aplicar horario"),
          ),
        ),

        const SizedBox(height: 24),

        // =======================
        // LISTA
        // =======================
        if (grouped.isEmpty)
          const Text("No hay horarios aún")
        else
          Column(
            children: grouped.entries.map((entry) {
              final day = entry.key;
              final list = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        dayNamesEs[weekDayToString(day)] ??
                            weekDayToString(day),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        list
                            .map((h) =>
                        "${DateFormatter.formatTime(h.startTime)} - ${DateFormatter.formatTime(h.endTime)}")
                            .join(" · "),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.navyBlue.withValues(alpha: 0.9),
                      ),
                      onPressed: () {
                        for (final h in list) {
                          widget.controller.removeHour(h);
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// =======================
// TIME BOX
// =======================

Widget _timeBox(
    BuildContext context, {
      required String label,
      required TimeOfDay? value,
      required ValueChanged<TimeOfDay> onPick,
    }) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: value ?? TimeOfDay.now(),
      );
      if (picked != null) onPick(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.navyBlue.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.navyBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            value?.format(context) ?? '--:--',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// =======================
// SHORTCUT BUTTON
// =======================

Widget _shortcut(String text, VoidCallback onTap) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.navyBlue,
      side: BorderSide(
        color: AppColors.navyBlue.withValues(alpha: 0.4),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w500),
    ),
  );
}
