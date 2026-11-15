import 'package:flutter/material.dart';
import '../../models/opening_hour_model.dart';

String formatHourString(String t) {
  final parts = t.split(":");
  if (parts.length >= 2) {
    return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
  }
  return t;
}

String fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

bool overlaps(OpeningHourModel a, OpeningHourModel b) {
  if (a.weekDay != b.weekDay) return false;
  return !(a.endTime.compareTo(b.startTime) <= 0 ||
      b.endTime.compareTo(a.startTime) <= 0);
}