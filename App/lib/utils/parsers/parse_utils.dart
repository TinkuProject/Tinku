double parseDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;

  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();

  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }

  return fallback;
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;

  if (value is int) return value;

  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }

  if (value is num) return value.toInt();

  return fallback;
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;

  if (value is bool) return value;

  if (value is String) {
    return value.toLowerCase() == 'true';
  }

  if (value is int) return value == 1;

  return fallback;
}