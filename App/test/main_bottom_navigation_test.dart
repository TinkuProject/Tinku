import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/widgets/common/navigation/main_bottom_navigation.dart';

void main() {
  testWidgets('la navegación principal funciona a 320 px y texto al 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: MainBottomNavigation(
            selectedIndex: selected,
            onDestinationSelected: (index) => selected = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Marketplace'));
    await tester.pump();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });
}
