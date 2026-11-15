import '../../core/enums.dart';

class ReservationModel {
  final int id;
  final String userId;
  final int eventId;
  final int? quantity;
  final double? tinkuAmount;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.quantity,
    this.tinkuAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      userId: json['user_id'],
      eventId: json['event_id'],
      quantity: json['quantity'],
      tinkuAmount: (json['tinku_amount'] as num).toDouble(),
      status: reservationStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'event_id': eventId,
      'quantity': quantity,
      'tinku_amount': tinkuAmount,
      'status': reservationStatusToString(status),
    };
  }
}