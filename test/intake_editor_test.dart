import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/case_form_section.dart';
import 'package:true_app/features/cases/presentation/intake/intake_editor.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const <CaseDraft>[];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

/// Secciones de mentira, altas, para comprobar el desplazamiento sin los
/// campos reales.
List<CaseFormSection> _tallSections() => [
  for (var i = 0; i < 4; i++)
    CaseFormSection(
      title: 'Sección $i',
      optional: i > 0,
      builder: (context) => SizedBox(height: 700, child: Text('cuerpo $i')),
    ),
];

Future<ProviderContainer> _pumpEditor(
  WidgetTester tester, {
  required Size size,
  List<CaseFormSection>? sections,
  IntakeEditorController? controller,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(_FakeCaseDraftsStore()),
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  final draftId = await container
      .read(caseDraftsProvider.notifier)
      .createDraft();
  container.read(editingDraftIdProvider.notifier).state = draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: IntakeEditor(
            sections: sections ?? kCaseFormSections,
            controller: controller,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

double _cardTop(WidgetTester tester, int index) =>
    tester.getTopLeft(find.byKey(Key('intake-editor-card-$index'))).dy;

void main() {
  testWidgets('numbers the registry cards 01 to 07 and marks optional ones', (
    tester,
  ) async {
    await _pumpEditor(tester, size: const Size(1440, 900));

    for (var i = 0; i < kCaseFormSections.length; i++) {
      final card = find.byKey(Key('intake-editor-card-$i'));
      final number = (i + 1).toString().padLeft(2, '0');
      expect(
        find.descendant(of: card, matching: find.text(number)),
        findsOneWidget,
        reason: 'número de la tarjeta $i',
      );
    }
    // Sólo las dos primeras son obligatorias; las otras cinco, opcionales.
    expect(
      find.descendant(
        of: find.byKey(const Key('intake-editor-card-0')),
        matching: find.text('OPCIONAL'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('intake-editor-card-1')),
        matching: find.text('OPCIONAL'),
      ),
      findsNothing,
    );
    for (var i = 2; i < kCaseFormSections.length; i++) {
      expect(
        find.descendant(
          of: find.byKey(Key('intake-editor-card-$i')),
          matching: find.text('OPCIONAL'),
        ),
        findsOneWidget,
        reason: 'etiqueta opcional de la tarjeta $i',
      );
    }
  });

  testWidgets('keeps the existing section fields inside the cards', (
    tester,
  ) async {
    await _pumpEditor(tester, size: const Size(1440, 900));

    expect(find.text('Datos básicos'), findsWidgets);
    expect(find.byKey(const Key('intake-field-country-0')), findsOneWidget);
  });

  testWidgets('navigation item scrolls to its section card', (tester) async {
    await _pumpEditor(
      tester,
      size: const Size(1440, 900),
      sections: _tallSections(),
    );
    expect(_cardTop(tester, 3), greaterThan(900));

    await tester.tap(find.byKey(const Key('intake-editor-nav-3')));
    await tester.pumpAndSettle();

    // La tarjeta queda bajo la barra de navegación fija, a la vista.
    expect(_cardTop(tester, 3), lessThan(300));
    expect(_cardTop(tester, 3), greaterThanOrEqualTo(0));
  });

  testWidgets('controller.scrollToSection scrolls to the requested card', (
    tester,
  ) async {
    final controller = IntakeEditorController();
    addTearDown(controller.dispose);
    await _pumpEditor(
      tester,
      size: const Size(390, 844),
      sections: _tallSections(),
      controller: controller,
    );
    expect(_cardTop(tester, 2), greaterThan(844));

    controller.scrollToSection(2);
    await tester.pumpAndSettle();

    expect(_cardTop(tester, 2), lessThan(300));
    expect(_cardTop(tester, 2), greaterThanOrEqualTo(0));
  });

  testWidgets('controller ignores out of range indexes', (tester) async {
    final controller = IntakeEditorController();
    addTearDown(controller.dispose);
    await _pumpEditor(
      tester,
      size: const Size(1440, 900),
      sections: _tallSections(),
      controller: controller,
    );
    final before = _cardTop(tester, 1);

    controller.scrollToSection(-1);
    controller.scrollToSection(99);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_cardTop(tester, 1), before);
  });

  bool navSelected(WidgetTester tester, int index) =>
      tester
          .widget<DsPressable>(
            find.descendant(
              of: find.byKey(Key('intake-editor-nav-$index')),
              matching: find.byType(DsPressable),
            ),
          )
          .selected ??
      false;

  testWidgets('active pill follows manual scrolling', (tester) async {
    await _pumpEditor(
      tester,
      size: const Size(1440, 900),
      sections: _tallSections(),
    );
    expect(navSelected(tester, 0), isTrue);

    final scroll = find.byKey(const Key('intake-editor-scroll'));
    // Arrastre manual: la tarjeta 2 sube hasta la parte alta del editor.
    final viewportTop = tester.getTopLeft(scroll).dy;
    final distance = _cardTop(tester, 2) - viewportTop - 30;
    await tester.drag(scroll, Offset(0, -distance));
    await tester.pumpAndSettle();

    expect(navSelected(tester, 2), isTrue);
    expect(navSelected(tester, 0), isFalse);

    await tester.drag(scroll, Offset(0, distance));
    await tester.pumpAndSettle();
    expect(navSelected(tester, 0), isTrue);
    expect(navSelected(tester, 2), isFalse);
  });

  testWidgets('tapping a pill keeps it active once the scroll settles', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      size: const Size(1440, 900),
      sections: _tallSections(),
    );

    await tester.tap(find.byKey(const Key('intake-editor-nav-3')));
    await tester.pumpAndSettle();

    expect(navSelected(tester, 3), isTrue);
    expect(navSelected(tester, 2), isFalse);
  });

  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    testWidgets('renders the real registry without overflow at ${size.width}', (
      tester,
    ) async {
      await _pumpEditor(tester, size: size);

      expect(tester.takeException(), isNull);
      for (var i = 0; i < kCaseFormSections.length; i++) {
        await tester.tap(find.byKey(Key('intake-editor-nav-$i')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
