import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_storage.dart';
import '../services/push_notification_service.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService authService;
  final UserService userService;
  final PushNotificationService pushNotificationService;

  UserProvider({
    required this.authService,
    required this.userService,
    required this.pushNotificationService,
  });

  UserModel? _user;
  bool _isLoading = true;
  bool _sessionRestoreFailed = false;
  String? _profilePicture;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get sessionRestoreFailed => _sessionRestoreFailed;
  String? get profilePicture => _profilePicture;

  // =========================
  // REALTIME (Disabled)
  // =========================
  void _subscribeToUserChanges(String userId) {
    // Realtime sync disabled after migration to pure PostgreSQL.
  }

  void _disposeRealtime() {
    // Realtime sync disabled after migration to pure PostgreSQL.
  }

  // =========================
  // SET SESSION
  // =========================
  Future<void> setSession({
    required UserModel user,
    required String accessToken,
    String? refreshToken,
  }) async {
    _user = user;

    await authService.persistSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _sessionRestoreFailed = false;

    _subscribeToUserChanges(user.id);

    await _loadProfilePicture();
    await _syncPushToken();

    notifyListeners();
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> clear({bool logoutOnServer = false}) async {
    _disposeRealtime();

    await _unregisterPushToken();

    _user = null;
    _profilePicture = null;
    _isLoading = false;
    _sessionRestoreFailed = false;

    if (logoutOnServer) {
      await authService.logout();
    } else {
      await authService.clearLocalSession();
    }

    notifyListeners();
  }

  // =========================
  // LOAD SESSION
  // =========================
  Future<void> loadSession({bool syncPushToken = true}) async {
    _isLoading = true;
    _sessionRestoreFailed = false;
    notifyListeners();

    try {
      final tokens = await AuthStorage.loadTokens();
      final access = tokens['accessToken'];
      final refresh = tokens['refreshToken'];

      if (access == null) {
        return;
      }

      authService.restoreSession(
        accessToken: access,
        refreshToken: refresh,
      );

      final validToken = await authService.getValidAccessToken();

      if (validToken == null) {
        _user = null;
        _profilePicture = null;
        return;
      }

      final profile = await authService.getCurrentUser();

      if (profile != null) {
        _user = profile;
        _subscribeToUserChanges(profile.id);
        await _loadProfilePicture();
        if (syncPushToken) {
          await _syncPushToken();
        }
      }
    } catch (_) {
      _sessionRestoreFailed = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> refreshCurrentUser() async {
    final profile = await authService.getCurrentUser();

    if (profile == null) {
      return null;
    }

    _user = profile;
    _subscribeToUserChanges(profile.id);
    await _loadProfilePicture();
    await _syncPushToken();
    notifyListeners();

    return profile;
  }

  // =========================
  // PROFILE PICTURE
  // =========================
  Future<void> _loadProfilePicture() async {
    if (_user == null) return;

    try {
      _profilePicture = await userService.getProfilePicture();
    } catch (_) {
      _profilePicture = null;
    }
  }

  // =========================
  // LOCAL UPDATE
  // =========================
  void updateLocally(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> _syncPushToken() async {
    try {
      await pushNotificationService.syncToken();
    } catch (_) {
      // El inicio de sesión no debe fallar por el registro push.
    }
  }

  Future<void> _unregisterPushToken() async {
    try {
      await pushNotificationService.unregisterCurrentToken();
    } catch (_) {
      // El cierre de sesión no debe quedar bloqueado por push.
    }
  }
}
