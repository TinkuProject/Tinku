import '../../core/enums.dart';

class EventTicketAttendeeModel {
  final String id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? ci;

  EventTicketAttendeeModel({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.ci,
  });

  factory EventTicketAttendeeModel.fromJson(Map<String, dynamic> json) {
    return EventTicketAttendeeModel(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      ci: json['ci'],
    );
  }

  String get displayName {
    final fullName = [firstName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');

    return fullName.isNotEmpty ? fullName : username;
  }
}

class EventTicketDayModel {
  final String id;
  final String ticketId;
  final int eventId;
  final String eventDate;
  final EventTicketStatus status;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime? usedAt;
  final String? usedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventTicketDayModel({
    required this.id,
    required this.ticketId,
    required this.eventId,
    required this.eventDate,
    required this.status,
    required this.validFrom,
    required this.validUntil,
    this.usedAt,
    this.usedBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventTicketDayModel.fromJson(Map<String, dynamic> json) {
    return EventTicketDayModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      eventId: json['event_id'],
      eventDate: json['event_date'],
      status: eventTicketStatusFromString(json['status']),
      validFrom: DateTime.parse(json['valid_from']).toLocal(),
      validUntil: DateTime.parse(json['valid_until']).toLocal(),
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'])?.toLocal()
          : null,
      usedBy: json['used_by'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])?.toLocal()
          : null,
    );
  }
}

class EventTicketModel {
  final String id;
  final int reservationId;
  final int eventId;
  final String userId;
  final int attendeeIndex;
  final EventTicketStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<EventTicketDayModel> days;
  final EventTicketAttendeeModel? attendee;

  EventTicketModel({
    required this.id,
    required this.reservationId,
    required this.eventId,
    required this.userId,
    required this.attendeeIndex,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.days = const [],
    this.attendee,
  });

  factory EventTicketModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['event_ticket_days'] ?? json['days'] ?? [];
    final rawAttendee = json['attendee'] ?? json['users'];

    final days = (rawDays as List)
        .map((e) => EventTicketDayModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList()
      ..sort((a, b) => a.validFrom.compareTo(b.validFrom));

    return EventTicketModel(
      id: json['id'],
      reservationId: json['reservation_id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      attendeeIndex: json['attendee_index'],
      status: eventTicketStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])?.toLocal()
          : null,
      days: days,
      attendee: rawAttendee != null
          ? EventTicketAttendeeModel.fromJson(
              Map<String, dynamic>.from(rawAttendee),
            )
          : null,
    );
  }
}

class EventTicketQrModel {
  final String ticketDayId;
  final String ticketId;
  final int reservationId;
  final int eventId;
  final String eventName;
  final String eventDate;
  final DateTime validFrom;
  final DateTime validUntil;
  final String qrToken;
  final Map<String, dynamic> qrPayload;

  EventTicketQrModel({
    required this.ticketDayId,
    required this.ticketId,
    required this.reservationId,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.validFrom,
    required this.validUntil,
    required this.qrToken,
    required this.qrPayload,
  });

  factory EventTicketQrModel.fromJson(Map<String, dynamic> json) {
    return EventTicketQrModel(
      ticketDayId: json['ticket_day_id'],
      ticketId: json['ticket_id'],
      reservationId: json['reservation_id'],
      eventId: json['event_id'],
      eventName: json['event_name'],
      eventDate: json['event_date'],
      validFrom: DateTime.parse(json['valid_from']).toLocal(),
      validUntil: DateTime.parse(json['valid_until']).toLocal(),
      qrToken: json['qr_token'],
      qrPayload: Map<String, dynamic>.from(json['qr_payload'] ?? {}),
    );
  }
}

class EventTicketCheckInResultModel {
  final String status;
  final String? reason;
  final String? ticketDayId;
  final String? ticketId;
  final int? reservationId;
  final int? eventId;
  final String? eventName;
  final String? eventDate;
  final DateTime? usedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;

  EventTicketCheckInResultModel({
    required this.status,
    this.reason,
    this.ticketDayId,
    this.ticketId,
    this.reservationId,
    this.eventId,
    this.eventName,
    this.eventDate,
    this.usedAt,
    this.validFrom,
    this.validUntil,
  });

  factory EventTicketCheckInResultModel.fromJson(Map<String, dynamic> json) {
    return EventTicketCheckInResultModel(
      status: json['status'],
      reason: json['reason'],
      ticketDayId: json['ticket_day_id'],
      ticketId: json['ticket_id'],
      reservationId: json['reservation_id'],
      eventId: json['event_id'],
      eventName: json['event_name'],
      eventDate: json['event_date'],
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'])?.toLocal()
          : null,
      validFrom: json['valid_from'] != null
          ? DateTime.tryParse(json['valid_from'])?.toLocal()
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'])?.toLocal()
          : null,
    );
  }

  bool get accepted => status == 'valid' || status == 'duplicate';
}
