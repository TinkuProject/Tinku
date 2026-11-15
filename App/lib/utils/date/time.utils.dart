import 'package:flutter/material.dart';

class TimeUtils {
  TimeUtils._();

  static String format(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return "$hh:$mm:00";
  }

  static String normalize(String time) {
    final parts = time.split(':');

    final hh = parts[0].padLeft(2, '0');
    final mm = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';

    return "$hh:$mm:00";
  }

  static int toMinutes(String time) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = parts.length > 1 ? int.parse(parts[1]) : 0;

    return h * 60 + m;
  }

  static bool isValidRange(String start, String end) {
    return toMinutes(start) < toMinutes(end);
  }
}