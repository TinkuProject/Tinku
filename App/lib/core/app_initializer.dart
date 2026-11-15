import 'dart:async';

import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../config/config.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/network_status_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_service.dart';

class AppDependencies {
  final AuthService authService;
  final UserService userService;
  final UserProvider userProvider;
  final PushNotificationService pushNotificationService;
  final NetworkStatusService networkStatusService;

  AppDependencies({
    required this.authService,
    required this.userService,
    required this.userProvider,
    required this.pushNotificationService,
    required this.networkStatusService,
  });
}

class AppInitializer {
  static AppDependencies create() {
    Intl.defaultLocale = 'es';

    final authService = AuthService();
    final userService = UserService(authService);
    final pushNotificationService = PushNotificationService(authService);
    final networkStatusService = NetworkStatusService.instance;
    final userProvider = UserProvider(
      authService: authService,
      userService: userService,
      pushNotificationService: pushNotificationService,
    );

    return AppDependencies(
      authService: authService,
      userService: userService,
      userProvider: userProvider,
      pushNotificationService: pushNotificationService,
      networkStatusService: networkStatusService,
    );
  }

  static Future<void> initializeDeferred(AppDependencies dependencies) async {
    unawaited(dependencies.networkStatusService.initialize());
    unawaited(_initializePlatformServices());

    final firebaseReady = _initializeFirebase(
      dependencies.pushNotificationService,
    );
    final sessionReady = dependencies.userProvider.loadSession(
      syncPushToken: false,
    );

    await sessionReady;
    final canUsePush = await firebaseReady;

    if (canUsePush && dependencies.userProvider.user != null) {
      try {
        await dependencies.pushNotificationService.syncToken();
      } catch (_) {
        // Push no debe afectar la sesión restaurada.
      }
      dependencies.pushNotificationService.openPendingNotification();
    }
  }

  static Future<bool> _initializeFirebase(
    PushNotificationService pushNotificationService,
  ) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await pushNotificationService.initialize();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _initializePlatformServices() async {
    await Future.wait([
      _ignoreFailure(
        () => SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      ),
      _ignoreFailure(() => initializeDateFormatting('es', null)),
      if (Config.stripePublishableKey.isNotEmpty)
        _ignoreFailure(() async {
          Stripe.publishableKey = Config.stripePublishableKey;
          await Stripe.instance.applySettings();
        }),
    ]);
  }

  static Future<void> _ignoreFailure(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (_) {
      // Estos servicios se pueden recuperar cuando vuelvan a utilizarse.
    }
  }
}
