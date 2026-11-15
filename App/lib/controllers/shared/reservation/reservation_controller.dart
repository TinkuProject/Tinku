import 'package:flutter/material.dart';
import '../../../models/reservation_model.dart';
import '../../../services/reservation_service.dart';

class ReservationController extends ChangeNotifier {
  ReservationController(this._service);

  final ReservationService _service;

  // =========================
  // STATE
  // =========================
  List<ReservationModel> reservations = [];
  bool loading = false;
  String? error;

  // =========================
  // LOAD MINE
  // =========================
  Future<void> loadMine() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      reservations = await _service.getMine();
    } catch (e) {
      error = _mapError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOAD BY EVENT
  // =========================
  Future<void> loadByEvent(int eventId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      reservations = await _service.getByEvent(eventId);
    } catch (e) {
      error = _mapError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // UPDATE
  // =========================
  Future<bool> updateReservation(
      int id,
      Map<String, dynamic> updates,
      ) async {
    try {
      final updated = await _service.updateReservation(id, updates);

      final index = reservations.indexWhere((r) => r.id == id);
      if (index != -1) {
        reservations[index] = updated;
        notifyListeners();
      }

      return true;
    } catch (e) {
      error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  // =========================
  // DELETE
  // =========================
  Future<bool> deleteReservation(int id) async {
    try {
      await _service.deleteReservation(id);

      reservations.removeWhere((r) => r.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  // =========================
  // RESET
  // =========================
  void reset() {
    reservations.clear();
    error = null;
    loading = false;
    notifyListeners();
  }

  String _mapError(Object e) {
    final msg = e.toString();

    if (msg.contains("capacity")) return "No hay cupos disponibles";
    if (msg.contains("balance")) return "No tienes suficientes tinkus";

    return "Ocurrió un error";
  }
}