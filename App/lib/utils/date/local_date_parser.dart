class LocalDateParser {
  static DateTime parse(dynamic value) {
    return tryParse(value) ?? _boliviaFallback();
  }

  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final normalized = _hasTimeZone(raw) ? raw : '${raw}Z';
    return DateTime.tryParse(normalized)?.toLocal();
  }

  static bool _hasTimeZone(String value) {
    return value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
  }

  static DateTime _boliviaFallback() {
    return DateTime.now().toUtc().subtract(const Duration(hours: 4));
  }
}
