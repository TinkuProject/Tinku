import 'dart:async';

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  late final StreamSubscription _foregroundSubscription;
  int _syncGeneration = 0;

  NotificationProvider(
    this._service,
    PushNotificationService pushNotificationService,
  ) {
    _foregroundSubscription =
        pushNotificationService.foregroundMessages.listen((_) {
      _unreadCount++;
      notifyListeners();
      unawaited(_reconcileUnreadCount());
    });
  }

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> _reconcileUnreadCount() async {
    final generation = ++_syncGeneration;
    try {
      final count = await _service.getUnreadCount();
      if (generation != _syncGeneration) return;
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Se conserva el incremento optimista hasta el próximo refresco.
    }
  }

  // =========================
  // LOAD UNREAD COUNT
  // =========================
  Future<void> loadUnreadCount() async {
    final generation = ++_syncGeneration;
    _loading = true;
    notifyListeners();

    try {
      final count = await _service.getUnreadCount();
      if (generation != _syncGeneration) return;
      _unreadCount = count;
    } catch (_) {
      if (generation != _syncGeneration) return;
      _unreadCount = 0;
    } finally {
      if (generation == _syncGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  // =========================
  // DECREASE
  // =========================
  void decreaseUnread() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  // =========================
  // RESET
  // =========================
  void reset() {
    _syncGeneration++;
    _unreadCount = 0;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _foregroundSubscription.cancel();
    super.dispose();
  }
}
