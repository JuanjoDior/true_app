import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_sources.dart';

const _sources = [
  CaseSource(
    id: 'wiki',
    title: 'Wikipedia — El caso del faro',
    url: 'https://www.wikipedia.org/wiki/Faro',
    kind: CaseSourceKind.investigation,
  ),
  CaseSource(
    id: 'pod',
    title: 'Episodio 12',
    url: 'https://podcasts.example.com/ep12',
    kind: CaseSourceKind.podcast,
  ),
];

Future<void> _pump(WidgetTester tester, List<CaseSource> sources) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: Scaffold(
        body: SizedBox(width: 400, child: DossierSources(sources: sources)),
      ),
    ),
  );
}

void main() {
  testWidgets('counts the sources in the section label', (tester) async {
    await _pump(tester, _sources);

    expect(find.text('FUENTES CITADAS · 2'), findsOneWidget);
  });

  testWidgets('shows kind, title and host of each source', (tester) async {
    await _pump(tester, _sources);

    expect(find.text('INVESTIGACIÓN'), findsOneWidget);
    expect(find.text('PODCAST'), findsOneWidget);
    expect(find.text('Wikipedia — El caso del faro'), findsOneWidget);
    expect(find.text('wikipedia.org'), findsOneWidget);
    expect(find.text('Episodio 12'), findsOneWidget);
    expect(find.text('podcasts.example.com'), findsOneWidget);
  });

  testWidgets('every card is a tap target of at least 44 px', (tester) async {
    await _pump(tester, _sources);

    for (final source in _sources) {
      final size = tester.getSize(
        find.byKey(DossierSourceKeys.card(source.id)),
      );
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('renders nothing without sources', (tester) async {
    await _pump(tester, const []);

    expect(find.textContaining('FUENTES CITADAS'), findsNothing);
  });

  testWidgets('source cards can be activated with the keyboard', (
    tester,
  ) async {
    CaseSource? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DossierSources(
            sources: _sources,
            onOpenSource: (source) => opened = source,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, same(_sources.first));
  });

  group('dossierSourceHost', () {
    test('drops the www prefix', () {
      expect(
        dossierSourceHost('https://www.sfchronicle.com/a'),
        'sfchronicle.com',
      );
    });

    test('keeps other subdomains', () {
      expect(
        dossierSourceHost('https://es.wikipedia.org/x'),
        'es.wikipedia.org',
      );
    });

    test('falls back to the raw text when there is no host', () {
      expect(dossierSourceHost('archivo local'), 'archivo local');
    });
  });
}
