import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/home/presentation/widgets/situation/situation_nav_rail.dart';
import 'package:true_app/features/home/presentation/widgets/situation/situation_side_panel.dart';

import 'test_support/sample_cases.dart';

/// Characterization lock for the Sala de Situación's responsive layout
/// selection, captured BEFORE migrating `home_page.dart`'s inline width
/// literals (880/980/1024/1100) to the shared `Breakpoints` module. Every
/// assertion here MUST stay GREEN after the migration — that is what proves
/// the migration is behavior-preserving, byte-for-byte.
///
/// Pre-existing, out-of-scope defect pinned as-is (approval-testing style):
/// `SituationTopBar` already overflows (`RenderFlex overflowed`) in two
/// measured bands, reproduced deterministically with the top bar in isolation
/// (so it is not caused by this test's fixtures or by sibling widgets):
///
/// | width | overflow |
/// |-------|----------|
/// | 980   | 21 px    |
/// | 1000  | 1.2 px   |
/// | 1010  | none     |
/// | 1024  | none     |
/// | 1030  | 59 px    |
/// | 1040  | 49 px    |
/// | 1050  | 39 px    |
/// | 1060  | 29 px    |
/// | 1080  | 9.4 px   |
/// | 1100  | none     |
///
/// Fixing it is out of Phase 1 scope (behavior-preserving rename only). This
/// test therefore tolerates that overflow ONLY at the widths measured to
/// exhibit it, and REQUIRES a clean pump everywhere else — so a newly
/// introduced overflow at 1440/900/800 still fails, instead of hiding behind a
/// blanket tolerance. That keeps the file a real safety net for its actual
/// subject: Requirement "Sala de Situación Layout Selection Is
/// Behavior-Preserving".
void main() {
  /// Widths measured to overflow today. Anything outside this set must pump
  /// clean; anything inside it may only throw `RenderFlex overflowed`.
  const overflowingWidths = <double>[1050, 1000];

  /// Returns `true` when this pump reported the known overflow. The defect is
  /// raised during layout, so a later pump that does not relayout the top bar
  /// legitimately reports nothing — hence "at least once per width" below,
  /// rather than "on every pump".
  bool drainExpectedException(WidgetTester tester, double width) {
    final exception = tester.takeException();
    if (exception == null) return false;

    expect(
      overflowingWidths.contains(width),
      isTrue,
      reason: 'Width $width px pumps clean today. A new exception here is a '
          'regression, not the known SituationTopBar defect.',
    );
    expect(
      exception.toString(),
      contains('RenderFlex overflowed'),
      reason: 'Only the known pre-existing SituationTopBar overflow is '
          'tolerated at width $width px; any other exception must fail.',
    );
    return true;
  }

  Future<ProviderContainer> pumpAt(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        casesRepositoryProvider
            .overrideWithValue(const FakeCasesRepository(sampleCases)),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TrueCrimeApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    var sawKnownOverflow = drainExpectedException(tester, width);

    // Selecciona un caso para poder comprobar la hoja móvil del expediente
    // por debajo del umbral `sidePanel`.
    container.read(selectedCaseIdProvider.notifier).state = 'zodiac-killer';
    await tester.pump(const Duration(milliseconds: 400));
    sawKnownOverflow |= drainExpectedException(tester, width);

    if (overflowingWidths.contains(width)) {
      expect(
        sawKnownOverflow,
        isTrue,
        reason: 'Width $width px is pinned as overflowing but pumped clean. If '
            'the SituationTopBar defect was fixed, remove $width from '
            'overflowingWidths so this tolerance disappears with it.',
      );
    }

    return container;
  }

  group('Sala de Situación layout selection is locked at each threshold', () {
    testWidgets(
      '1440px: nav rail + 362px panel + metrics visible, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 1440);

        expect(find.byType(SituationNavRail), findsOneWidget);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 362);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsOneWidget);
        expect(find.text('Global ▾'), findsOneWidget);
      },
    );

    testWidgets(
      '1050px: no nav rail, 362px panel, metrics visible, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 1050);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 362);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsOneWidget);
        expect(find.text('Global ▾'), findsOneWidget);
      },
    );

    testWidgets(
      '1000px: no nav rail, 320px panel, metrics still visible, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 1000);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 320);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsOneWidget);
        expect(find.text('Global ▾'), findsOneWidget);
      },
    );

    testWidgets(
      '900px: no nav rail, 320px panel, compact top bar, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 900);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 320);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsNothing);
        expect(find.text('Global ▾'), findsNothing);
      },
    );

    testWidgets(
      '800px: mobile body with floating dossier sheet, compact top bar',
      (tester) async {
        await pumpAt(tester, 800);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(find.byType(SituationSidePanel), findsNothing);
        expect(find.byKey(const Key('mobile-case-sheet')), findsOneWidget);
        expect(find.text('DOCUMENTADOS'), findsNothing);
        expect(find.text('Global ▾'), findsNothing);
      },
    );
  });
}
