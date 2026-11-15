import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/widgets/common/network_connection_gate.dart';

void main() {
  testWidgets('muestra el estado sin conexión y permite reintentar', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: NoConnectionScreen(
          onRetry: () async {
            retries++;
            return false;
          },
        ),
      ),
    );

    expect(find.text('Sin conexión a internet'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.text('Volver a intentar'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('desactiva el reintento mientras comprueba la red', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: NoConnectionScreen(
          isChecking: true,
          onRetry: () async {
            retries++;
            return false;
          },
        ),
      ),
    );

    expect(find.text('Comprobando…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Comprobando…'));
    await tester.pump();

    expect(retries, 0);
  });
}
