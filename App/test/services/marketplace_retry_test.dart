import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinkuapp/core/session_manager.dart';
import 'package:tinkuapp/providers/user_provider.dart';
import 'package:tinkuapp/services/auth_service.dart';
import 'package:tinkuapp/services/marketplace_service.dart';
import 'package:tinkuapp/services/push_notification_service.dart';
import 'package:tinkuapp/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SessionManager.clear();
  });
  tearDown(SessionManager.clear);

  test('a failed purchase reuses its durable idempotency key', () async {
    final ids = <String>[];
    final auth = AuthService(client: MockClient((request) async {
      final data = jsonDecode(request.body) as Map<String, dynamic>;
      ids.add(data['client_request_id'] as String);
      if (ids.length == 1) return http.Response('{}', 503);
      return http.Response(
          jsonEncode({
            'id': 1,
            'buyer_id': 'buyer',
            'status': 'paid',
            'total_tinkus': 10
          }),
          201);
    }));
    auth.restoreSession(accessToken: _token(), refreshToken: 'refresh');
    final service = MarketplaceService(auth);
    Future<dynamic> purchase() => service.createOrder(
        publicationId: 1,
        quantity: 1,
        paymentMethod: 'tinkus',
        fulfillment: 'pickup',
        pickupBusinessId: 1);
    await expectLater(purchase(), throwsA(isA<ApiException>()));
    await purchase();
    await purchase();
    expect(ids[0], ids[1]);
    expect(ids[2], isNot(ids[1]));
  });

  test('device token is removed before logout clears credentials', () async {
    final actions = <String>[];
    final auth = AuthService(client: MockClient((request) async {
      actions.add('remote logout');
      return http.Response('{}', 200);
    }));
    auth.restoreSession(accessToken: _token(), refreshToken: 'refresh');
    final push = _Push(auth, actions);
    final provider = UserProvider(
        authService: auth,
        userService: UserService(auth),
        pushNotificationService: push);
    await provider.clear(logoutOnServer: true);
    expect(actions, ['unregister', 'remote logout']);
    expect(SessionManager.accessToken, isNull);
    provider.dispose();
  });

  test('refund and pickup errors explain the actual problem', () {
    expect(
        ApiException(
                409, '{"error":"Organizer balance is insufficient for refund"}')
            .userMessage,
        contains('organizador'));
    expect(
        ApiException(409, '{"error":"Marketplace pickup expired"}').userMessage,
        contains('plazo de retiro'));
  });
}

class _Push extends PushNotificationService {
  _Push(super.authService, this.actions);
  final List<String> actions;
  @override
  Future<void> unregisterCurrentToken() async {
    expect(SessionManager.accessToken, isNotNull);
    actions.add('unregister');
  }
}

String _token() {
  final payload = base64Url.encode(utf8.encode(jsonEncode({
    'sub': 'buyer',
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
  })));
  return 'header.$payload.signature';
}
