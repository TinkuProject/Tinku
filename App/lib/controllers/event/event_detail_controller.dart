import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/event_model.dart';
import '../../models/business_model.dart';
import '../../models/user_model.dart';
import '../../models/media_model.dart';
import '../../models/event_ticket_model.dart';
import '../../models/entity_transport_relation_model.dart';
import '../../models/transport_line_model.dart';
import '../../models/transport_route_model.dart';

import '../../services/event_service.dart';
import '../../services/business_service.dart';
import '../../services/reservation_service.dart';
import '../../services/media_service.dart';
import '../../services/event_ticket_service.dart';

import '../../controllers/shared/review/reviews_controller.dart';
import '../../controllers/shared/transport/entity_transport_controller.dart';

import '../../providers/user_provider.dart';
import '../../services/user_service.dart';

class EventDetailController extends ChangeNotifier {
  EventDetailController(
      this._eventSvc,
      this._businessSvc,
      this._reservationSvc,
      this._mediaSvc,
      this._ticketSvc,
      this._userSvc,
      this.userProvider,

      // INYECTADOS
      this.reviewsController,
      this.transportC,
      ) {
    reviewsController.addListener(notifyListeners);
    transportC.addListener(notifyListeners);
  }

  final EventService _eventSvc;
  final BusinessService _businessSvc;
  final ReservationService _reservationSvc;
  final MediaService _mediaSvc;
  final EventTicketService _ticketSvc;
  final UserService _userSvc;
  final UserProvider userProvider;

  final ReviewsController reviewsController;
  final EntityTransportController transportC;

  // =========================
  // STATE
  // =========================
  late EventModel event;

  // Owner
  BusinessModel? business;
  UserModel? organizer;
  bool loadingBusiness = false;
  bool loadingOrganizer = false;

  // Media
  List<MediaModel> media = [];
  bool loadingMedia = false;

  // UI
  int currentPage = 0;

  // Reservations
  bool loadingReservation = false;
  bool isConfirmed = false;
  String? currentUserId;

  // Capacity
  bool loadingCapacity = false;
  int confirmedReservations = 0;
  int? remainingSpots;
  bool isFull = false;

  // Attendance
  final List<EventTicketModel> attendeeTickets = [];
  final List<EventTicketModel> myTickets = [];
  bool loadingAttendees = false;
  bool loadingMyTickets = false;
  bool issuingQr = false;
  bool validatingQr = false;
  EventTicketQrModel? lastIssuedQr;

  // =========================
  // INIT
  // =========================
  Future<void> init(EventModel e, {String? currentUserId}) async {
    event = e;
    this.currentUserId = currentUserId;
    notifyListeners();

    transportC.setContext(
      entityType: VisitEntity.event,
      entityId: e.id,
    );

    final detailLoaded = await _loadDetailAggregate();

    final futures = <Future<void>>[
      reviewsController.load(
        targetId: e.id,
        targetType: ReviewEntityType.event,
        ownerUserId: e.creatorId,
      ),
    ];

    if (!detailLoaded) {
      futures.addAll([
        _loadOwnerIfBusiness(),
        _loadMedia(),
        _loadCapacity(),
        transportC.loadSelectedOnly(
          entityType: VisitEntity.event,
          entityId: e.id,
        ),
      ]);
    }

    await Future.wait(futures);

    if (currentUserId != null) {
      await checkReservation();
      if (isConfirmed && !canManageEvent) {
        await loadMyTickets();
      }
    }

    if (canManageEvent) {
      await loadAttendees();
    }
  }

  Future<void> refresh() async {
    final detailLoaded = await _loadDetailAggregate();

    if (detailLoaded) {
      notifyListeners();
      return;
    }

    final updated = await _eventSvc.getById(event.id);

    if (updated != null) {
      event = updated;

      await Future.wait([
        _loadMedia(),
        transportC.loadSelectedOnly(
          entityType: VisitEntity.event,
          entityId: event.id,
        ),
      ]);

      notifyListeners();
    }
  }

  // =========================
  // OWNER
  // =========================
  Future<void> _loadOwnerIfBusiness() async {
    if (event.businessId != null) {
      loadingBusiness = true;
      notifyListeners();

      try {
        business = await _businessSvc.getById(event.businessId!);
      } catch (_) {
        business = null;
      } finally {
        loadingBusiness = false;
        notifyListeners();
      }

      return;
    }

    if (event.creatorId.isNotEmpty) {
      loadingOrganizer = true;
      notifyListeners();

      try {
        final users = await _userSvc.getByIds([event.creatorId]);
        organizer = users[event.creatorId];
      } catch (_) {
        organizer = null;
      } finally {
        loadingOrganizer = false;
        notifyListeners();
      }
    }
  }

  // =========================
  // MEDIA
  // =========================
  Future<void> _loadMedia() async {
    loadingMedia = true;
    notifyListeners();

    try {
      media = await _mediaSvc.getByEntity(
        entityId: event.id.toString(),
        entityType: MediaEntityType.event,
      );
    } finally {
      loadingMedia = false;
      notifyListeners();
    }
  }

  void advanceCarousel() {
    if (media.length > 1) {
      currentPage = (currentPage + 1) % media.length;
      notifyListeners();
    }
  }

  // =========================
  // PERMISSIONS
  // =========================
  bool canEdit({required String? currentUserId}) {
    if (currentUserId == null) return false;

    return event.creatorId == currentUserId ||
        business?.ownerId == currentUserId;
  }

  bool get canManageEvent => canEdit(currentUserId: currentUserId);

  bool get canReviewEvent =>
      currentUserId != null && isConfirmed && !canManageEvent;

  // =========================
  // RESERVATIONS
  // =========================
  Future<void> checkReservation() async {
    if (currentUserId == null) return;

    loadingReservation = true;
    notifyListeners();

    try {
      final reservations = await _reservationSvc.getMineByEvent(event.id);

      isConfirmed = reservations.any(
            (r) => r.status == ReservationStatus.confirmed,
      );
    } catch (_) {
      isConfirmed = false;
    } finally {
      loadingReservation = false;
      notifyListeners();
    }
  }

  Future<(bool, String)> reserveAndPay() async {
    if (currentUserId == null) {
      return (false, "Usuario no identificado");
    }

    if (isConfirmed) {
      return (false, "Ya estás asistiendo a este evento");
    }

    if (loadingReservation) {
      return (false, "Procesando...");
    }

    loadingReservation = true;
    notifyListeners();

    try {
      final reservation = await _reservationSvc.createReservation(
        eventId: event.id,
        quantity: 1,
      );

      if (reservation.status == ReservationStatus.confirmed) {
        isConfirmed = true;
      }

      await checkReservation();
      await loadMyTickets();
      await _loadCapacity();

      return (true, "Reserva confirmada");
    } catch (e) {
      final msg = e.toString();

      if (msg.contains("capacity")) {
        return (false, "No hay cupos disponibles");
      }

      if (msg.contains("balance")) {
        return (false, "No tienes suficientes tinkus");
      }

      return (false, "No se pudo completar la reserva");
    } finally {
      loadingReservation = false;
      notifyListeners();
    }
  }

  // =========================
  // CAPACITY
  // =========================
  Future<void> _loadCapacity() async {
    loadingCapacity = true;
    notifyListeners();

    try {
      final data = await _eventSvc.getAvailability(event.id);

      confirmedReservations = data['confirmed'] ?? 0;
      isFull = data['is_full'] ?? false;
      remainingSpots = data['remaining'];
    } catch (_) {
      confirmedReservations = 0;
      remainingSpots = null;
      isFull = false;
    } finally {
      loadingCapacity = false;
      notifyListeners();
    }
  }

  bool get hasLimit =>
      event.capacity != null && event.capacity! > 0;

  bool get isFinished =>
      event.status == EventStatus.finished;

  bool get showLowCapacityWarning {
    if (!hasLimit || remainingSpots == null) return false;
    return remainingSpots! <= 10;
  }

  bool get isFree => event.tinkuPrice == 0;

  Future<void> loadAttendees() async {
    if (!canManageEvent) return;

    loadingAttendees = true;
    notifyListeners();

    try {
      final tickets = await _ticketSvc.getByEvent(event.id);
      attendeeTickets
        ..clear()
        ..addAll(tickets);
    } finally {
      loadingAttendees = false;
      notifyListeners();
    }
  }

  Future<bool> _loadDetailAggregate() async {
    loadingBusiness = true;
    loadingOrganizer = true;
    loadingMedia = true;
    loadingCapacity = true;
    notifyListeners();

    try {
      final detail = await _eventSvc.getDetail(event.id);

      final eventMap = _asMap(detail['event']);
      if (eventMap != null) {
        event = EventModel.fromJson(eventMap);
      }

      final businessMap = _asMap(detail['business']);
      business = businessMap != null ? BusinessModel.fromJson(businessMap) : null;

      final organizerMap = _asMap(detail['organizer']);
      organizer = organizerMap != null ? UserModel.fromJson(organizerMap) : null;

      media = _parseList(detail['media'], MediaModel.fromJson);

      final availability = _asMap(detail['availability']);
      confirmedReservations = availability?['confirmed'] ?? 0;
      isFull = availability?['is_full'] ?? false;
      remainingSpots = availability?['remaining'];

      final relations = _parseList(
        detail['transport_relations'],
        EntityTransportRelationModel.fromJson,
      );
      final lines =
          _parseList(detail['transport_lines'], TransportLineModel.fromJson);
      final routes = _parseTransportRouteMap(detail['transport_routes']);

      transportC.setLoaded(
        relations: relations,
        lines: lines,
        routes: routes,
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      loadingBusiness = false;
      loadingOrganizer = false;
      loadingMedia = false;
      loadingCapacity = false;
      notifyListeners();
    }
  }

  Future<void> loadMyTickets() async {
    if (currentUserId == null) return;

    loadingMyTickets = true;
    notifyListeners();

    try {
      final tickets = await _ticketSvc.getMine();
      myTickets
        ..clear()
        ..addAll(tickets.where((ticket) => ticket.eventId == event.id));
    } finally {
      loadingMyTickets = false;
      notifyListeners();
    }
  }

  Future<EventTicketQrModel?> issueQrForFirstAvailableDay() async {
    issuingQr = true;
    notifyListeners();

    try {
      if (myTickets.isEmpty) {
        await loadMyTickets();
      }

      EventTicketDayModel? currentDay;
      EventTicketDayModel? nextDay;
      var hasExpiredTicket = false;
      final now = DateTime.now();

      for (final ticket in myTickets) {
        for (final day in ticket.days) {
          if (day.status != EventTicketStatus.active || day.usedAt != null) {
            continue;
          }

          if (day.validUntil.isBefore(now)) {
            hasExpiredTicket = true;
            continue;
          }

          if (!day.validFrom.isAfter(now) && !day.validUntil.isBefore(now)) {
            currentDay = day;
            break;
          }

          if (nextDay == null && day.validFrom.isAfter(now)) {
            nextDay = day;
          }
        }
        if (currentDay != null) break;
      }

      final targetDay = currentDay ?? nextDay;

      if (targetDay == null) {
        if (hasExpiredTicket) {
          throw Exception('El ticket de asistencia está vencido');
        }

        return null;
      }

      final qr = await _ticketSvc.issueQr(targetDay.id);
      lastIssuedQr = qr;
      return qr;
    } finally {
      issuingQr = false;
      notifyListeners();
    }
  }

  Future<EventTicketCheckInResultModel> validateQrInput(String rawInput) async {
    final token = _extractQrToken(rawInput);

    if (token == null || token.isEmpty) {
      throw Exception('QR inválido');
    }

    validatingQr = true;
    notifyListeners();

    try {
      final result = await _ticketSvc.checkIn(
        token: token,
        eventId: event.id,
      );

      await loadAttendees();
      return result;
    } finally {
      validatingQr = false;
      notifyListeners();
    }
  }

  String? _extractQrToken(String rawInput) {
    final value = rawInput.trim();
    if (value.isEmpty) return null;

    if (!value.startsWith('{')) return value;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return value;

      final direct = decoded['qr_token'] ?? decoded['token'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final payload = decoded['qr_payload'];
      if (payload is Map) {
        final nested = payload['qr_token'] ?? payload['token'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }

      return value;
    } catch (_) {
      return value;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const [];
  }

  List<T> _parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return _asList(value)
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, List<TransportRouteModel>> _parseTransportRouteMap(
    dynamic value,
  ) {
    final result = <String, List<TransportRouteModel>>{};
    final rawMap = value is Map ? value : const {};

    for (final entry in rawMap.entries) {
      result[entry.key.toString()] = _parseList(
        entry.value,
        TransportRouteModel.fromJson,
      );
    }

    return result;
  }

  @override
  void dispose() {
    reviewsController.removeListener(notifyListeners);
    transportC.removeListener(notifyListeners);
    super.dispose();
  }
}
