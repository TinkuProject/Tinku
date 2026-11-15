import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  // =========================
  // EVENT RANGE (UI BONITO)
  // =========================
  static String eventRange(DateTime start, DateTime end) {
    final day = DateFormat('dd');
    final month = DateFormat('MMM');
    final full = DateFormat('dd MMM');

    final sameDay =
        start.day == end.day &&
            start.month == end.month &&
            start.year == end.year;

    final sameMonth =
        start.month == end.month &&
            start.year == end.year;

    if (sameDay) {
      return full.format(start);
    } else if (sameMonth) {
      return "${day.format(start)} - ${day.format(end)} ${month.format(start)}";
    } else {
      return "${full.format(start)} - ${full.format(end)}";
    }
  }

  // =========================
  // SIMPLE RANGE (DD/MM)
  // =========================
  static String simpleRange(DateTime start, DateTime end) {
    final s = start.toLocal();
    final e = end.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    final startStr = '${two(s.day)}/${two(s.month)}';
    final endStr = '${two(e.day)}/${two(e.month)}';

    if (startStr == endStr) {
      return 'Solo el $startStr';
    }

    return '$startStr – $endStr';
  }

  // =========================
  // TRANSACTION DATE
  // =========================
  static String transaction(DateTime d) {
    final date = d.toLocal();
    final now = DateTime.now().toLocal();

    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(date.year, date.month, date.day);

    if (dDay == today) {
      return 'Hoy • ${DateFormat('HH:mm').format(date)}';
    }

    if (dDay == today.subtract(const Duration(days: 1))) {
      return 'Ayer • ${DateFormat('HH:mm').format(date)}';
    }

    return '${DateFormat.E('es_ES').format(date).substring(0, 3)} • ${DateFormat('HH:mm').format(date)}';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return "";

    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  static String formDateTime(DateTime? date) {
    if (date == null) return "";

    final d = date.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(d.day)}/${two(d.month)}/${d.year} • ${two(d.hour)}:${two(d.minute)}";
  }

  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return "";

    final parts = time.split(':');
    if (parts.length < 2) return time;

    return "${parts[0]}:${parts[1]}";
  }
}