import '../models/opening_hour_model.dart';
import '../utils/date/time.utils.dart';

class OpeningHoursValidator {
  OpeningHoursValidator._();

  // =========================
  // VALIDATE RANGE
  // =========================
  static void validateRange(OpeningHourModel hour) {
    final start = TimeUtils.normalize(hour.startTime);
    final end = TimeUtils.normalize(hour.endTime);

    if (!TimeUtils.isValidRange(start, end)) {
      throw OpeningHourException(
        "El horario de apertura debe ser menor al de cierre",
      );
    }
  }

  // =========================
  // OVERLAP CHECK
  // =========================
  static bool overlaps(
      OpeningHourModel a,
      OpeningHourModel b,
      ) {
    final aStart = TimeUtils.toMinutes(a.startTime);
    final aEnd = TimeUtils.toMinutes(a.endTime);

    final bStart = TimeUtils.toMinutes(b.startTime);
    final bEnd = TimeUtils.toMinutes(b.endTime);

    return aStart < bEnd && bStart < aEnd;
  }

  // =========================
  // VALIDATE NO OVERLAP
  // =========================
  static void validateNoOverlap(
      List<OpeningHourModel> existing,
      OpeningHourModel newHour,
      ) {
    for (final h in existing) {
      if (h.weekDay != newHour.weekDay) continue;

      if (overlaps(h, newHour)) {
        throw OpeningHourException(
          "El horario se superpone con otro existente",
        );
      }
    }
  }

  // =========================
  // FULL VALIDATION
  // =========================
  static void validateNewHour(
      List<OpeningHourModel> existing,
      OpeningHourModel newHour,
      ) {
    validateRange(newHour);
    validateNoOverlap(existing, newHour);
  }
}

// =========================
// CUSTOM EXCEPTION
// =========================
class OpeningHourException implements Exception {
  final String message;

  OpeningHourException(this.message);

  @override
  String toString() => message;
}