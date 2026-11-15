import 'dart:convert';
import '../../models/reservation_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class ReservationService extends BaseService<ReservationModel> {
  ReservationService(AuthService authService)
      : super("reservations", authService);

  @override
  ReservationModel fromJson(Map<String, dynamic> json) {
    return ReservationModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ReservationModel model) {
    return model.toJson();
  }

  Future<ReservationModel> createReservation({
    required int eventId,
    required int quantity,
  }) async {
    final response = await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode({
          'event_id': eventId,
          'quantity': quantity,
        }),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // GET MINE
  // =========================
  Future<List<ReservationModel>> getMine() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ReservationModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY EVENT
  // =========================
  Future<List<ReservationModel>> getByEvent(int eventId) async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/event/$eventId'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ReservationModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
// GET MINE BY EVENT
// =========================
  Future<List<ReservationModel>> getMineByEvent(int eventId) async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/event/$eventId/me'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ReservationModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // UPDATE
  // =========================
  Future<ReservationModel> updateReservation(
      int id,
      Map<String, dynamic> updates,
      ) async {
    final response = await request(
          () async => client.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // DELETE
  // =========================
  Future<void> deleteReservation(int id) async {
    await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }
}