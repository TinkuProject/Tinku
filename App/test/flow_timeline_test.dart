import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/helpers/flow_timeline_helper.dart';
import 'package:tinkuapp/widgets/common/flow_timeline.dart';

void main() {
  test('el flujo de aprobación representa pendiente, aprobado y rechazado', () {
    final pending = FlowTimelineHelper.approval(
      status: ApprovalStatus.pending,
    );
    final approved = FlowTimelineHelper.approval(
      status: ApprovalStatus.approved,
    );
    final rejected = FlowTimelineHelper.approval(
      status: ApprovalStatus.rejected,
    );

    expect(pending.map((step) => step.state), [
      FlowTimelineStepState.completed,
      FlowTimelineStepState.current,
      FlowTimelineStepState.upcoming,
    ]);
    expect(
      approved.every(
        (step) => step.state == FlowTimelineStepState.completed,
      ),
      isTrue,
    );
    expect(rejected.last.label, 'Solicitud rechazada');
    expect(rejected.last.state, FlowTimelineStepState.error);
  });

  testWidgets('la línea de tiempo se adapta a 320 px y texto al 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final steps = FlowTimelineHelper.approval(
      status: ApprovalStatus.pending,
      submittedLabel: 'Solicitud de aprobación enviada',
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: FlowTimelinePanel(
              title: 'Proceso de aprobación',
              steps: steps,
              initiallyExpanded: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solicitud de aprobación enviada'), findsOneWidget);
    expect(find.text('Revisión administrativa'), findsWidgets);
    expect(find.text('Solicitud aprobada'), findsOneWidget);
    expect(find.text('Actual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
