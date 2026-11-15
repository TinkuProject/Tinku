import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

import '../config/config.dart';
import '../core/navigation.dart';
import '../core/session_manager.dart';
import '../ui/themes/colors.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService(this._authService);

  final AuthService _authService;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static bool _foregroundListenerReady = false;
  static bool _notificationOpenListenerReady = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();
  RemoteMessage? _pendingInitialMessage;

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;

  Future<void> initialize() async {
    await _messaging.setAutoInitEnabled(true);
    await _requestPermission();
    _listenForegroundMessages();
    _listenNotificationOpens();
    _pendingInitialMessage = await _messaging.getInitialMessage();
  }

  void openPendingNotification() {
    final message = _pendingInitialMessage;
    if (message == null) return;
    _pendingInitialMessage = null;
    _openNotifications(message);
  }

  Future<void> syncToken() async {
    await _requestPermission();
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _registerToken(token);

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((nextToken) {
      _registerToken(nextToken);
    });
  }

  Future<void> unregisterCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _authService.client.post(
      Uri.parse('${Config.baseUrl}/notifications/device-tokens/remove'),
      headers: await _authService.authHeaders(),
      body: jsonEncode({
        'token': token,
        'platform': Platform.operatingSystem,
      }),
      );
      if (response.statusCode >= 400) throw ApiException(response.statusCode, response.body);
    } finally {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      await _messaging.deleteToken();
    }
  }

  Future<void> _registerToken(String token) async {
    if (!SessionManager.isAuthenticated) return;
    await _authService.client.post(
      Uri.parse('${Config.baseUrl}/notifications/device-tokens'),
      headers: await _authService.authHeaders(),
      body: jsonEncode({
        'token': token,
        'platform': Platform.operatingSystem,
      }),
    );
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _listenForegroundMessages() {
    if (_foregroundListenerReady) return;
    _foregroundListenerReady = true;

    FirebaseMessaging.onMessage.listen((message) {
      if (!SessionManager.isAuthenticated) return;
      _foregroundMessages.add(message);
      final title = message.notification?.title ?? 'Tinku';
      final body = message.notification?.body ?? '';

      if (body.trim().isEmpty) return;

      showOverlayNotification(
        (context) => SafeArea(
          child: GestureDetector(
            onTap: () {
              OverlaySupportEntry.of(context)?.dismiss();
              _openNotifications(message);
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.darkBlue),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.darkBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: const TextStyle(
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        position: NotificationPosition.top,
      );
    });
  }

  void _listenNotificationOpens() {
    if (_notificationOpenListenerReady) return;
    _notificationOpenListenerReady = true;
    FirebaseMessaging.onMessageOpenedApp.listen(_openNotifications);
  }

  void _openNotifications(RemoteMessage message) {
    final candidate = message.data['route'] ?? message.data['screen'];
    final route = candidate is String && candidate.startsWith('/')
        ? candidate
        : '/notifications';
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed(route);
      });
      return;
    }
    navigator.pushNamed(route);
  }
}
