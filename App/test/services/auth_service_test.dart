import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tinkuapp/core/app_initializer.dart';
import 'package:tinkuapp/core/session_manager.dart';
import 'package:tinkuapp/providers/user_provider.dart';
import 'package:tinkuapp/services/auth_service.dart';
import 'package:tinkuapp/services/push_notification_service.dart';
import 'package:tinkuapp/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SessionManager.clear();
  });

  tearDown(SessionManager.clear);

  test('creates startup dependencies without remote initialization', () {
    final dependencies = AppInitializer.create();

    expect(dependencies.userProvider.isLoading, isTrue);
    expect(dependencies.userProvider.user, isNull);
  });

  test('shares one refresh operation across concurrent requests', () async {
    var refreshCalls = 0;
    final refreshedAccess = _token(expiresIn: const Duration(hours: 1));
    final authService = AuthService(
      baseUrl: 'https://tinku.test',
      client: MockClient((request) async {
        if (request.url.path == '/auth/refresh') {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({
              'session': {
                'access_token': refreshedAccess,
                'refresh_token': 'rotated-refresh',
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }),
    );
    authService.restoreSession(
      accessToken: _token(expiresIn: const Duration(seconds: -10)),
      refreshToken: 'original-refresh',
    );

    final tokens = await Future.wait([
      authService.getValidAccessToken(),
      authService.getValidAccessToken(),
      authService.getValidAccessToken(),
    ]);

    expect(tokens, everyElement(refreshedAccess));
    expect(refreshCalls, 1);
    expect(SessionManager.refreshToken, 'rotated-refresh');
  });

  test('refreshes once after concurrent 401 responses', () async {
    var refreshCalls = 0;
    var rejectedRequests = 0;
    final refreshedAccess = _token(expiresIn: const Duration(hours: 1));
    final oldAccess =
        _token(expiresIn: const Duration(hours: 1), marker: 'old');
    final authService = AuthService(
      baseUrl: 'https://tinku.test',
      client: MockClient((request) async {
        if (request.url.path == '/auth/refresh') {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({
              'session': {
                'access_token': refreshedAccess,
                'refresh_token': 'rotated-refresh',
              },
            }),
            200,
          );
        }

        if (request.url.path == '/auth/me') {
          final authorization = request.headers['authorization'];
          if (authorization == 'Bearer $oldAccess') {
            rejectedRequests++;
            return http.Response('Unauthorized', 401);
          }

          if (authorization == 'Bearer $refreshedAccess') {
            return http.Response(jsonEncode({'profile': _profileJson}), 200);
          }
        }

        return http.Response('Not found', 404);
      }),
    );
    authService.restoreSession(
      accessToken: oldAccess,
      refreshToken: 'original-refresh',
    );

    final users = await Future.wait([
      authService.getCurrentUser(),
      authService.getCurrentUser(),
    ]);

    expect(users.whereType<Object>(), hasLength(2));
    expect(rejectedRequests, 2);
    expect(refreshCalls, 1);
  });

  test('keeps stored credentials after a temporary restore failure', () async {
    final access = _token(expiresIn: const Duration(hours: 1));
    FlutterSecureStorage.setMockInitialValues({
      'access_token': access,
      'refresh_token': 'valid-refresh',
    });
    final authService = AuthService(
      baseUrl: 'https://tinku.test',
      client: MockClient((_) async {
        throw http.ClientException('Temporary network error');
      }),
    );
    final provider = UserProvider(
      authService: authService,
      userService: UserService(authService),
      pushNotificationService: PushNotificationService(authService),
    );

    await provider.loadSession(syncPushToken: false);

    expect(provider.sessionRestoreFailed, isTrue);
    expect(SessionManager.accessToken, access);
    expect(SessionManager.refreshToken, 'valid-refresh');
  });
}

String _token({
  required Duration expiresIn,
  String marker = 'token',
}) {
  final expiration =
      DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'exp': expiration, 'marker': marker})),
  );
  return '${header.replaceAll('=', '')}.${payload.replaceAll('=', '')}.signature';
}

final _profileJson = {
  'id': '00000000-0000-0000-0000-000000000001',
  'username': 'test_user',
  'email': 'test@tinku.test',
  'role': 'user',
  'status': 'active',
  'created_at': '2026-01-01T00:00:00.000Z',
};
