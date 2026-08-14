import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';
import 'package:true_app/features/cases/presentation/intake/sections/chapters_section.dart';

import 'test_support/sample_cases.dart';

/// Escribir un capítulo y verlo aparecer en la previsualización, sin pasar por
/// el disco ni recargar nada [spec: case-editorial-chapters, Draft Persistence
/// and Live Preview].
///
/// Editor y previsualización se montan JUNTOS, que es como los usa quien
/// escribe. Probarlos por separado dejaría sin cubrir justamente el cable que
/// los une.

class _FakeStore implements CaseDraftsStore {
  _FakeStore(this._drafts);

  List<CaseDraft> _drafts;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _drafts;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => _drafts = drafts;
}

const _headings = {
  'ANTECEDENTES',
  'LOS HECHOS',
  'LA INVESTIGACIÓN',
  'ESTADO ACTUAL',
};

Key _fieldKey(CaseChapterType type) =>
    Key('intake-field-chapter-draft-a-${type.name}');

Future<ProviderContainer> _pumpBoth(
  WidgetTester tester, {
  CaseChapters chapters = const CaseChapters(),
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(
        _FakeStore([CaseDraft(draftId: 'draft-a', chapters: chapters)]),
      ),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
    ],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  container.read(editingDraftIdProvider.notifier).state = 'draft-a';

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(child: SingleChildScrollView(child: ChaptersSection())),
              Expanded(child: IntakePreviewPanel()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Acotado a la previsualización a propósito.
///
/// El editor y la previsualización comparten árbol, así que buscar en todo él
/// haría que un texto del formulario contase como si estuviese previsualizado.
/// Hoy no colisionan — el editor rotula 'Los hechos' y la previsualización
/// 'LOS HECHOS' — pero apoyarse en esa diferencia de mayúsculas sería apoyarse
/// en una casualidad.
List<String> _previewHeadings(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(IntakePreviewPanel),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data)
      .whereType<String>()
      .where(_headings.contains)
      .toList(growable: false);
}

Finder _inPreview(String text) => find.descendant(
  of: find.byType(IntakePreviewPanel),
  matching: find.text(text),
);

void main() {
  testWidgets('a chapter typed in the editor appears in the preview', (
    tester,
  ) async {
    await _pumpBoth(tester);

    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.events)),
      'Aquella noche de temporal',
    );
    await tester.pump();

    expect(_inPreview('Aquella noche de temporal'), findsOneWidget);
  });

  testWidgets('its heading appears with it', (tester) async {
    await _pumpBoth(tester);

    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.events)),
      'Aquella noche',
    );
    await tester.pump();

    expect(_previewHeadings(tester), orderedEquals(const ['LOS HECHOS']));
  });

  testWidgets('the preview keeps the editorial order, not the typing order', (
    tester,
  ) async {
    await _pumpBoth(tester);

    // Se escribe el último primero y el primero después.
    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.currentStatus)),
      'Ahora',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.background)),
      'Antes',
    );
    await tester.pump();

    expect(
      _previewHeadings(tester),
      orderedEquals(const ['ANTECEDENTES', 'ESTADO ACTUAL']),
    );
  });

  // El nombre NO promete "sin bombear": `enterText` bombea por dentro, así que
  // prometerlo sería mentir. El escenario de dos ediciones en el mismo frame lo
  // cubre `two edits in the same frame both survive`, en el test del editor,
  // disparando los `onChanged` a mano.
  testWidgets('two edits in a row both reach the preview', (tester) async {
    await _pumpBoth(tester);

    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.background)),
      'Antes',
    );
    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.events)),
      'Después',
    );
    await tester.pump();

    expect(
      _previewHeadings(tester),
      orderedEquals(const ['ANTECEDENTES', 'LOS HECHOS']),
    );
  });

  testWidgets('clearing a chapter removes it from the preview', (tester) async {
    await _pumpBoth(
      tester,
      chapters: const CaseChapters(background: 'Antes', events: 'Después'),
    );

    await tester.enterText(
      find.byKey(_fieldKey(CaseChapterType.background)),
      '  ',
    );
    await tester.pump();

    expect(_previewHeadings(tester), orderedEquals(const ['LOS HECHOS']));
  });

  testWidgets('a draft with no chapters previews no heading', (tester) async {
    await _pumpBoth(tester);

    expect(_previewHeadings(tester), isEmpty);
  });

  testWidgets('the preview still shows no map chrome', (tester) async {
    await _pumpBoth(tester, chapters: const CaseChapters(background: 'Antes'));

    expect(find.text('VOLVER AL MAPA'), findsNothing);
  });
}
