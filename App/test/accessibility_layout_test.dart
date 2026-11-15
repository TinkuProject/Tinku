import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/components/drawer_item.dart';
import 'package:tinkuapp/utils/accessibility/color_contrast.dart';
import 'package:tinkuapp/widgets/common/buttons/primary_button.dart';
import 'package:tinkuapp/widgets/common/buttons/secondary_button.dart';
import 'package:tinkuapp/widgets/common/empty/app_empty.dart';
import 'package:tinkuapp/widgets/common/entity_manage/entity_manage_card.dart';
import 'package:tinkuapp/widgets/common/loaders/app_loader.dart';
import 'package:tinkuapp/widgets/common/navigation/custom_app_bar.dart';
import 'package:tinkuapp/widgets/filters/filter_chip.dart';

void main() {
  test('ajusta colores de estado al contraste mínimo AA', () {
    const background = Colors.white;
    final readableGreen = accessibleOnLight(
      const Color(0xFF2ECC71),
      background,
    );

    expect(contrastRatio(readableGreen, background), greaterThanOrEqualTo(4.5));
  });

  Future<void> pumpAtSize(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: widget!,
        ),
        home: child,
      ),
    );
    await tester.pump();
  }

  testWidgets('controles compartidos no desbordan a 320 px y texto al 200%',
      (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(320, 800),
      textScale: 2,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: 'Confirmar operación del marketplace',
                icon: Icons.check,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Volver a configurar opciones',
                icon: Icons.settings,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              FilterChipWidget(
                icon: Icons.filter_alt_outlined,
                label: 'Negocio',
                value: 'Nombre comercial especialmente largo',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(PrimaryButton)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(SecondaryButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('card de gestión se adapta a 320 px y texto al 200%',
      (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(320, 900),
      textScale: 2,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: EntityManageCard(
            title: 'Negocio con un nombre comercial considerablemente largo',
            category: 'Servicios profesionales especializados',
            location: 'Avenida principal, zona central de Cochabamba',
            organizer: 'Responsable de la organización',
            imageUrl: '',
            statusLabel: 'Pendiente de aprobación',
            statusColor: Colors.orange,
            statusIcon: Icons.schedule,
            statusSubtitle: 'Esperando revisión administrativa',
            views: 1234,
            rating: 4.8,
            date: '23/09/2026',
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Estado: Pendiente de aprobación',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Vistas: 1234',
      ),
      findsOneWidget,
    );
  });

  testWidgets('estado vacío y app bar resisten 360 px y texto al 150%',
      (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(360, 800),
      textScale: 1.5,
      child: const Scaffold(
        appBar: CustomAppBar(
          title: 'Administración de almacenes',
          subtitle: 'Solicitudes pendientes de revisión',
        ),
        body: AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Todavía no hay productos disponibles',
          subtitle:
              'Cuando se registren productos para este negocio aparecerán en esta sección.',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('loader fullscreen conserva restricciones dentro de un Stack',
      (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      child: const Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 48),
                Expanded(child: SizedBox()),
              ],
            ),
            AppLoader(message: 'Cargando tus servicios...'),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(AppLoader)),
      const Size(320, 640),
    );
  });

  testWidgets('opción del menú conserva objetivo táctil y semántica',
      (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(320, 600),
      textScale: 2,
      child: Scaffold(
        backgroundColor: Colors.blueGrey,
        body: DrawerItem(
          icon: Icons.notifications,
          title: 'Notificaciones y actividad',
          badgeCount: 12,
          onTap: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final semanticItem = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label ==
              'Notificaciones y actividad, 12 notificaciones sin leer',
    );
    expect(semanticItem, findsOneWidget);
    expect(
      tester.getSize(find.byType(DrawerItem)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
