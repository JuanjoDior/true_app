import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';

import 'test_support/sample_cases.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesRepositoryProvider.overrideWithValue(
            const FakeCasesRepository(sampleCases),
          ),
          mapConfigProvider.overrideWithValue(MapConfig.testing()),
        ],
        child: const TrueCrimeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders header, search and featured rail', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(1440, 1200));

    expect(find.byKey(const Key('case-search-field')), findsOneWidget);
    expect(find.text('Cartelera'), findsOneWidget);
    expect(
      find.byKey(const Key('featured-case-card-zodiac-killer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('featured-case-card-alcasser-girls')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('featured-case-card-manson-family-murders')),
      findsOneWidget,
    );
  });

  testWidgets('opens desktop detail panel from featured card', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(1440, 1200));

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
    expect(find.text('Investigación'), findsOneWidget);
    expect(find.text('Podcast'), findsOneWidget);
  });

  testWidgets('opens mobile bottom sheet for selected case', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(430, 932));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrueCrimeApp)),
    );
    container.read(selectedCaseIdProvider.notifier).state = 'zodiac-killer';
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-case-sheet')), findsOneWidget);
    expect(find.text('Zodiac Killer'), findsAtLeastNWidgets(1));
  });
}
