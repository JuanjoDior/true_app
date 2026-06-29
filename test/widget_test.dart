import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

import 'test_support/sample_cases.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    Size size, {
    List<TrueCrimeCase> cases = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesRepositoryProvider.overrideWithValue(FakeCasesRepository(cases)),
          mapConfigProvider.overrideWithValue(MapConfig.testing()),
        ],
        child: const TrueCrimeApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
  }

  testWidgets('renders the situation room shell with search and status filters',
      (WidgetTester tester) async {
    await pumpApp(tester, const Size(1440, 1200));

    expect(find.byKey(const Key('case-search-field')), findsOneWidget);
    expect(find.byKey(const Key('status-chip-all')), findsOneWidget);
    expect(find.byKey(const Key('status-chip-open')), findsOneWidget);
    expect(find.byKey(const Key('status-chip-solved')), findsOneWidget);
    expect(find.byKey(const Key('status-chip-progress')), findsOneWidget);
    expect(find.text('ACTUALIZACIONES RECIENTES'), findsOneWidget);
  });

  testWidgets('shows the featured focus panel when nothing is selected',
      (WidgetTester tester) async {
    await pumpApp(tester, const Size(1440, 1200), cases: sampleCases);

    expect(find.text('EN EL FOCO'), findsOneWidget);
    expect(find.text('Abrir expediente'), findsOneWidget);
  });

  testWidgets('filters map markers by search query',
      (WidgetTester tester) async {
    await pumpApp(tester, const Size(1440, 1200), cases: sampleCases);

    expect(find.byKey(const Key('marker-zodiac-killer')), findsOneWidget);
    expect(find.byKey(const Key('marker-madeleine-mccann')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('case-search-field')),
      'mccann',
    );
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const Key('marker-madeleine-mccann')), findsOneWidget);
    expect(find.byKey(const Key('marker-zodiac-killer')), findsNothing);
    expect(find.byKey(const Key('marker-black-dahlia')), findsNothing);
  });

  testWidgets('opens the dossier from the featured "Abrir expediente" button',
      (WidgetTester tester) async {
    await pumpApp(tester, const Size(1440, 1200), cases: sampleCases);

    await tester.tap(find.text('Abrir expediente'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const Key('detail-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('detail-panel')),
        matching: find.text('Zodiac Killer'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the dossier by selecting a case',
      (WidgetTester tester) async {
    await pumpApp(tester, const Size(1440, 1200), cases: sampleCases);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrueCrimeApp)),
    );
    container.read(selectedCaseIdProvider.notifier).state = 'black-dahlia';
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const Key('detail-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('detail-panel')),
        matching: find.text('Black Dahlia'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a mobile bottom sheet for the selected case',
      (WidgetTester tester) async {
    await pumpApp(tester, const Size(430, 932), cases: sampleCases);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrueCrimeApp)),
    );
    container.read(selectedCaseIdProvider.notifier).state = 'zodiac-killer';
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const Key('mobile-case-sheet')), findsOneWidget);
    expect(find.text('Zodiac Killer'), findsAtLeastNWidgets(1));
  });
}
