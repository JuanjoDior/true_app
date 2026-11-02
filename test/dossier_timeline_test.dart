import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_timeline.dart';

const _events = [
  CaseTimelineEvent(
    title: 'Desaparece el farero',
    date: '1974',
    kind: CaseTimelineKind.initial,
  ),
  CaseTimelineEvent(
    title: 'Se reabre la pesquisa',
    date: '1980–81',
    kind: CaseTimelineKind.process,
  ),
  CaseTimelineEvent(
    title: 'Investigación aún abierta',
    date: 'Hoy',
    kind: CaseTimelineKind.open,
  ),
  CaseTimelineEvent(
    title: 'Se identifica al autor',
    date: '2019',
    kind: CaseTimelineKind.solved,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: const Scaffold(
        body: SingleChildScrollView(child: DossierTimeline(events: _events)),
      ),
    ),
  );
}

void main() {
  testWidgets('shows date, title and kind text for every milestone', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('CRONOLOGÍA VERIFICADA'), findsOneWidget);
    for (final event in _events) {
      expect(find.text(event.date), findsOneWidget);
      expect(find.text(event.title), findsOneWidget);
    }
    expect(find.text('HECHO INICIAL'), findsOneWidget);
    expect(find.text('INVESTIGACIÓN'), findsOneWidget);
    expect(find.text('SIGUE ABIERTO'), findsOneWidget);
    expect(find.text('RESOLUCIÓN'), findsOneWidget);
  });

  testWidgets('colours each date with the tone of its kind', (tester) async {
    await _pump(tester);

    Color? dateColor(String date) =>
        tester.widget<Text>(find.text(date)).style?.color;

    expect(dateColor('1974'), DsColors.accentRed);
    expect(dateColor('1980–81'), DsColors.accentGold);
    expect(dateColor('Hoy'), DsStatusColors.open);
    expect(dateColor('2019'), DsStatusColors.solved);
  });

  testWidgets('renders nothing without events', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.build(),
        home: const Scaffold(body: DossierTimeline(events: [])),
      ),
    );

    expect(find.text('CRONOLOGÍA VERIFICADA'), findsNothing);
  });

  testWidgets('does not overflow at 360 px', (tester) async {
    await _pump(tester, size: const Size(360, 780));

    expect(tester.takeException(), isNull);
  });
}
