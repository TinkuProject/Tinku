import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/models/home_dashboard_model.dart';
import 'package:tinkuapp/models/user_model.dart';
import 'package:tinkuapp/providers/user_provider.dart';
import 'package:tinkuapp/services/auth_service.dart';
import 'package:tinkuapp/services/push_notification_service.dart';
import 'package:tinkuapp/services/user_service.dart';
import 'package:tinkuapp/views/home/role_home_dashboard.dart';

void main() {
  test('interpreta el resumen administrativo agregado', () {
    final model = HomeDashboardModel.fromJson({
      'mode': 'admin',
      'admin': {
        'businesses': 2,
        'events': 3,
        'warehouses': 1,
        'claims': 4,
        'total': 10,
      },
    });

    expect(model.mode, 'admin');
    expect(model.admin?.total, 10);
    expect(model.admin?.claims, 4);
  });

  testWidgets('el inicio de socio resiste 320 px y texto al 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final auth = AuthService(
      baseUrl: 'https://tinku.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'mode': 'partner',
            'partner': {
              'total_sales': 12,
              'active_sales': 3,
              'delivered_sales': 9,
              'active_publications': 5,
              'sold_out_publications': 1,
              'pending_tasks': 2,
            },
            'warehouse': {
              'owned': 1,
              'pending_receptions': 2,
              'incoming_shipments': 1,
              'pending_deliveries': 3,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final user = UserModel(
      id: 'partner-id',
      username: 'Socio Tinku',
      email: 'socio@tinku.test',
      role: UserRole.partner,
      status: UserStatus.active,
      createdAt: DateTime(2026),
    );
    final provider = UserProvider(
      authService: auth,
      userService: UserService(auth),
      pushNotificationService: PushNotificationService(auth),
    )..updateLocally(user);

    await tester.pumpWidget(
      ChangeNotifierProvider<UserProvider>.value(
        value: provider,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: RoleHomeDashboard(user: user),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Tu actividad comercial'), findsOneWidget);
    expect(find.text('Ventas activas'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Operación de almacenes'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Operación de almacenes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
