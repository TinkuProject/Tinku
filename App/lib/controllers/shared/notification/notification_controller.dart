import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _service;

  NotificationController(this._service);

  // =========================
  // STATE
  // =========================
  final List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool loading = false;
  bool clearingAll = false;
  bool _realtimeInitialized = false;
  Timer? _pollingTimer;

  Future<void> initRealtime(String userId) async {
    if (_realtimeInitialized) return;
    _realtimeInitialized = true;

    await load();

    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!loading && !clearingAll) {
        unawaited(refresh());
      }
    });
  }

  // =========================
  // LOAD
  // =========================
  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      final list = await _service.getMine();

      notifications
        ..clear()
        ..addAll(list);

      unreadCount = notifications.where((n) => !n.read).length;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  // =========================
  // MARK AS READ
  // =========================
  Future<void> markAsRead(int id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final wasUnread = !notifications[index].read;

    // UI optimista
    notifications[index] = notifications[index].copyWith(read: true);
    if (wasUnread && unreadCount > 0) unreadCount--;
    notifyListeners();

    try {
      await _service.markAsRead(id);
    } catch (e) {
      // rollback simple si falla
      notifications[index] = notifications[index].copyWith(read: false);
      if (wasUnread) unreadCount++;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    if (notifications.isEmpty) return;

    loading = true;
    notifyListeners();

    try {
      await _service.markAllAsRead();

      for (var i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(read: true);
      }

      unreadCount = 0;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // DELETE ONE
  // =========================
  Future<void> delete(int id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final removed = notifications[index];
    final wasUnread = !removed.read;

    notifications.removeAt(index);
    if (wasUnread && unreadCount > 0) unreadCount--;
    notifyListeners();

    try {
      await _service.deleteNotification(id);
    } catch (e) {
      // rollback si falla
      notifications.insert(index, removed);
      if (wasUnread) unreadCount++;
      notifyListeners();
      rethrow;
    }
  }

  // =========================
  // DELETE ALL
  // =========================
  Future<void> deleteAll() async {
    if (clearingAll || notifications.isEmpty) return;

    clearingAll = true;
    notifyListeners();

    final backup = List<NotificationModel>.from(notifications);
    final backupUnread = unreadCount;

    try {
      // Crear bulk
      for (final n in backup) {
        await _service.deleteNotification(n.id);
      }

      notifications.clear();
      unreadCount = 0;
    } catch (e) {
      notifications
        ..clear()
        ..addAll(backup);
      unreadCount = backupUnread;
      rethrow;
    } finally {
      clearingAll = false;
      notifyListeners();
    }
  }

  Future<void> notifyAdmins({
    required String message,
    required String? senderId,
  }) async {
    await _service.notifyAdmins(
      message: message,
      senderId: senderId,
    );
  }

  Future<void> disposeRealtime() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _realtimeInitialized = false;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
