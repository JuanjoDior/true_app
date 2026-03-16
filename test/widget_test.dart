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
    await tester.pumpAndSettle();
  }

  testWidgets('renders empty home with filters and empty states', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(1440, 1200));

    expect(find.byKey(const Key('case-search-field')), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.byKey(const Key('catalog-empty-message')), findsOneWidget);
    expect(find.byKey(const Key('featured-rail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('case-world-map-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('category-chip-all')), findsOneWidget);
    expect(
      find.byKey(const Key('category-chip-isolatedMurder')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('category-chip-serialKiller')), findsOneWidget);
    expect(find.byKey(const Key('category-chip-kidnapping')), findsOneWidget);
    expect(find.byKey(const Key('category-chip-unsolved')), findsOneWidget);

    await tester.tap(find.byKey(const Key('case-search-field')));
    await tester.pumpAndSettle();

    expect(find.text('Zodiac Killer'), findsNothing);
  });

  testWidgets('opens desktop detail panel from featured card', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(1440, 1200), cases: sampleCases);

    await tester.tap(find.byKey(const Key('featured-case-card-zodiac-killer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('detail-panel')),
        matching: find.text('Zodiac Killer'),
      ),
      findsOneWidget,
    );
    expect(find.text('Asesinos en serie'), findsWidgets);
    expect(find.text('Investigación'), findsOneWidget);
    expect(find.text('Podcast'), findsOneWidget);
  });

  testWidgets('filters map markers by category', (WidgetTester tester) async {
    await pumpApp(tester, const Size(1440, 1200), cases: sampleCases);

    expect(find.byKey(const Key('marker-zodiac-killer')), findsOneWidget);
    expect(find.byKey(const Key('marker-madeleine-mccann')), findsOneWidget);
    expect(find.byKey(const Key('marker-black-dahlia')), findsOneWidget);
    expect(find.byKey(const Key('marker-meredith-kercher')), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-chip-kidnapping')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('marker-madeleine-mccann')), findsOneWidget);
    expect(find.byKey(const Key('marker-zodiac-killer')), findsNothing);
    expect(find.byKey(const Key('marker-black-dahlia')), findsNothing);
    expect(find.byKey(const Key('marker-meredith-kercher')), findsNothing);
  });

  testWidgets('opens mobile bottom sheet for selected case', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(430, 932), cases: sampleCases);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrueCrimeApp)),
    );
    container.read(selectedCaseIdProvider.notifier).state = 'zodiac-killer';
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-case-sheet')), findsOneWidget);
    expect(find.text('Zodiac Killer'), findsAtLeastNWidgets(1));
  });
}
