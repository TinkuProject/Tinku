import '../../core/enums.dart';

class OpeningHourModel {
  final int id;
  final OpeningEntity entityType;
  final int entityId;
  final WeekDay weekDay;
  final String startTime; // HH:mm:ss
  final String endTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OpeningHourModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.weekDay,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    this.updatedAt,
  });

  factory OpeningHourModel.fromJson(Map<String, dynamic> json) {
    return OpeningHourModel(
      id: json['id'],
      entityType: openingEntityFromString(json['entity_type']),
      entityId: json['entity_id'],
      weekDay: weekDayFromString(json['week_day']),
      startTime: _extractTime(json['start_time']),
      endTime: _extractTime(json['end_time']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_type': openingEntityToString(entityType),
      'entity_id': entityId,
      'week_day': weekDayToString(weekDay),
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  OpeningHourModel copyWith({
    int? id,
    OpeningEntity? entityType,
    int? entityId,
    WeekDay? weekDay,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OpeningHourModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      weekDay: weekDay ?? this.weekDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // =========================
  // HELPER
  // =========================
  static String _extractTime(dynamic value) {
    if (value == null) return "00:00:00";

    String str = value.toString();

    // Caso ISO: 2026-04-12T08:00:00.000Z
    if (str.contains('T')) {
      str = str.split('T')[1].split('.').first;
    }

    final parts = str.split(':');

    final hh = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
    final mm = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';

    return "$hh:$mm:00";
  }
}