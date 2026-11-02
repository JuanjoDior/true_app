import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_related.dart';

TrueCrimeCase _crimeCase(
  String id,
  String title,
  CaseCategory category,
  int year,
) {
  return TrueCrimeCase(
    id: id,
    slug: id,
    title: title,
    category: category,
    country: 'EE. UU.',
    countryCode: 'US',
    regionOrCity: 'California',
    year: year,
    latitude: 37.7,
    longitude: -122.4,
    summary: 'Resumen.',
    tags: const [],
    sources: const [],
  );
}

final _related = <RelatedCase>[
  (
    crimeCase: _crimeCase(
      'gsk',
      'Golden State Killer',
      CaseCategory.serialKiller,
      1976,
    ),
    relation: 'Norte de California',
  ),
  (
    crimeCase: _crimeCase(
      'dahlia',
      'Black Dahlia',
      CaseCategory.unsolved,
      1947,
    ),
    relation: 'California · sin resolver',
  ),
];

Future<List<TrueCrimeCase>> _pump(
  WidgetTester tester,
  List<RelatedCase> related,
) async {
  final opened = <TrueCrimeCase>[];
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: DossierRelated(relatedCases: related, onOpen: opened.add),
        ),
      ),
    ),
  );
  return opened;
}

void main() {
  testWidgets('shows category, ghost year, title and relation', (tester) async {
    await _pump(tester, _related);

    expect(find.text('CASOS RELACIONADOS'), findsOneWidget);
    expect(find.text('ASESINOS EN SERIE'), findsOneWidget);
    expect(find.text('CASOS SIN RESOLVER'), findsOneWidget);
    expect(find.text('1976'), findsOneWidget);
    expect(find.text('Golden State Killer'), findsOneWidget);
    expect(find.text('Norte de California'), findsOneWidget);
    expect(find.text('Black Dahlia'), findsOneWidget);
  });

  testWidgets('tapping a poster opens that case', (tester) async {
    final opened = await _pump(tester, _related);

    await tester.tap(find.byKey(DossierRelatedKeys.poster('dahlia')));
    await tester.pump();

    expect(opened.map((c) => c.id), orderedEquals(const ['dahlia']));
  });

  testWidgets('posters are landscape and about 136 px high', (tester) async {
    await _pump(tester, _related);

    final size = tester.getSize(find.byKey(DossierRelatedKeys.poster('gsk')));
    expect(size.height, DossierRelatedMetrics.posterHeight);
    expect(size.width, greaterThan(size.height));
  });

  testWidgets('every poster fills its available parent width', (tester) async {
    await _pump(tester, _related);

    final parentWidth = tester.getSize(find.byType(DossierRelated)).width;
    expect(parentWidth, 400);
    for (final related in _related) {
      expect(
        tester
            .getSize(
              find.byKey(DossierRelatedKeys.poster(related.crimeCase.id)),
            )
            .width,
        parentWidth,
      );
    }
  });

  testWidgets('small category text never uses the raw accent red', (
    tester,
  ) async {
    await _pump(tester, _related);

    final label = tester.widget<Text>(find.text('ASESINOS EN SERIE'));
    expect(label.style?.color, isNot(DsColors.accentRed));
    expect(label.style?.color, DsColors.accentRedText);
  });

  testWidgets('renders nothing without related cases', (tester) async {
    await _pump(tester, const []);

    expect(find.text('CASOS RELACIONADOS'), findsNothing);
  });
}
