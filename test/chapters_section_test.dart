import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/sections/chapters_section.dart';

/// El editor de capítulos [spec: case-editorial-chapters].
///
/// Cuatro campos fijos, ni uno más: la sección NO ofrece añadir, borrar ni
/// reordenar. Esa ausencia es un requisito, no un descuido, y por eso tiene
/// tests propios — un control de más rompería el orden editorial garantizado.

class _FakeStore implements CaseDraftsStore {
  _FakeStore(this._drafts);

  List<CaseDraft> _drafts;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _drafts;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => _drafts = drafts;
}

Key _fieldKey(String draftId, CaseChapterType type) =>
    Key('intake-field-chapter-$draftId-${type.name}');

Future<ProviderContainer> _pumpSection(
  WidgetTester tester, {
  List<CaseDraft> drafts = const [CaseDraft(draftId: 'draft-a')],
  String editing = 'draft-a',
}) async {
  final container = ProviderContainer(
    overrides: [caseDraftsStoreProvider.overrideWithValue(_FakeStore(drafts))],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  container.read(editingDraftIdProvider.notifier).state = editing;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ChaptersSection())),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Dispara el `onChanged` de un campo sin bombear un frame.
void _fire(
  WidgetTester tester,
  String draftId,
  CaseChapterType type,
  String value,
) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(_fieldKey(draftId, type)),
      matching: find.byType(EditableText),
    ),
  );
  editable.onChanged!(value);
}

CaseDraft _draftIn(ProviderContainer container, String draftId) {
  return container
      .read(caseDraftsProvider)
      .value!
      .firstWhere((draft) => draft.draftId == draftId);
}

void main() {
  group('cuatro campos fijos', () {
    testWidgets('renders one field per chapter type', (tester) async {
      await _pumpSection(tester);

      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('labels them in the fixed editorial order', (tester) async {
      await _pumpSection(tester);

      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where(
              {
                'Antecedentes',
                'Los hechos',
                'La investigación',
                'Estado actual',
              }.contains,
            ),
        orderedEquals(const [
          'Antecedentes',
          'Los hechos',
          'La investigación',
          'Estado actual',
        ]),
      );
    });

    testWidgets('every field carries a key scoped to draft and type', (
      tester,
    ) async {
      await _pumpSection(tester);

      for (final type in CaseChapterType.values) {
        expect(find.byKey(_fieldKey('draft-a', type)), findsOneWidget);
      }
    });
  });

  group('sin controles arbitrarios', () {
    // Los cuatro tipos son fijos por especificación. Un botón de añadir, de
    // borrar o de reordenar rompería esa garantía, así que su ausencia se
    // afirma en vez de darse por supuesta.
    testWidgets('offers no button at all', (tester) async {
      await _pumpSection(tester);

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('offers no icon button either', (tester) async {
      await _pumpSection(tester);

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('offers no reordering affordance', (tester) async {
      await _pumpSection(tester);

      expect(find.byType(ReorderableListView), findsNothing);
    });
  });

  group('editar y limpiar', () {
    testWidgets('typing into a field stores that chapter', (tester) async {
      final container = await _pumpSection(tester);

      await tester.enterText(
        find.byKey(_fieldKey('draft-a', CaseChapterType.events)),
        'Aquella noche',
      );
      await tester.pump();

      expect(
        _draftIn(
          container,
          'draft-a',
        ).chapters.contentFor(CaseChapterType.events),
        'Aquella noche',
      );
    });

    testWidgets('typing into one field leaves the others alone', (
      tester,
    ) async {
      final container = await _pumpSection(
        tester,
        drafts: const [
          CaseDraft(
            draftId: 'draft-a',
            chapters: CaseChapters(background: 'Antes'),
          ),
        ],
      );

      await tester.enterText(
        find.byKey(_fieldKey('draft-a', CaseChapterType.events)),
        'Aquella noche',
      );
      await tester.pump();

      expect(
        _draftIn(
          container,
          'draft-a',
        ).chapters.contentFor(CaseChapterType.background),
        'Antes',
      );
    });

    testWidgets('two edits in the same frame both survive', (tester) async {
      final container = await _pumpSection(tester);

      // Se disparan los dos `onChanged` a mano y SIN bombear entre medias,
      // que es la única forma de reproducir el escenario: `enterText` bombea
      // por dentro, así que con él siempre hay una reconstrucción de por medio
      // y la diferencia entre editar el borrador vigente y editar la copia
      // capturada en el `build` se vuelve invisible.
      //
      // El escenario es real: `editDraft` publica el estado de forma síncrona
      // pero el widget no se reconstruye hasta el frame siguiente, así que dos
      // pulsaciones rápidas comparten el mismo `build`.
      _fire(tester, 'draft-a', CaseChapterType.background, 'Antes');
      _fire(tester, 'draft-a', CaseChapterType.events, 'Después');
      await tester.pump();

      expect(
        _draftIn(
          container,
          'draft-a',
        ).chapters.orderedMeaningful.map((chapter) => chapter.content),
        orderedEquals(const ['Antes', 'Después']),
      );
    });

    testWidgets('clearing a field drops that chapter', (tester) async {
      final container = await _pumpSection(
        tester,
        drafts: const [
          CaseDraft(
            draftId: 'draft-a',
            chapters: CaseChapters(background: 'Antes', events: 'Después'),
          ),
        ],
      );

      await tester.enterText(
        find.byKey(_fieldKey('draft-a', CaseChapterType.background)),
        '   ',
      );
      await tester.pump();

      expect(
        _draftIn(
          container,
          'draft-a',
        ).chapters.orderedMeaningful.map((chapter) => chapter.type),
        orderedEquals(const [CaseChapterType.events]),
      );
    });
  });

  group('cambiar de borrador', () {
    testWidgets('the fields show the newly selected draft content', (
      tester,
    ) async {
      final container = await _pumpSection(
        tester,
        drafts: const [
          CaseDraft(
            draftId: 'draft-a',
            chapters: CaseChapters(background: 'De A'),
          ),
          CaseDraft(
            draftId: 'draft-b',
            chapters: CaseChapters(background: 'De B'),
          ),
        ],
      );

      container.read(editingDraftIdProvider.notifier).state = 'draft-b';
      await tester.pump();

      // `TextFormField` ignora los cambios de `initialValue`, así que sin una
      // clave que dependa del borrador el campo seguiría enseñando 'De A'.
      expect(find.text('De B'), findsOneWidget);
    });

    testWidgets('the previous draft content is gone from the fields', (
      tester,
    ) async {
      final container = await _pumpSection(
        tester,
        drafts: const [
          CaseDraft(
            draftId: 'draft-a',
            chapters: CaseChapters(background: 'De A'),
          ),
          CaseDraft(
            draftId: 'draft-b',
            chapters: CaseChapters(background: 'De B'),
          ),
        ],
      );

      container.read(editingDraftIdProvider.notifier).state = 'draft-b';
      await tester.pump();

      expect(find.text('De A'), findsNothing);
    });

    testWidgets('editing after switching writes to the new draft', (
      tester,
    ) async {
      final container = await _pumpSection(
        tester,
        drafts: const [
          CaseDraft(draftId: 'draft-a'),
          CaseDraft(draftId: 'draft-b'),
        ],
      );

      container.read(editingDraftIdProvider.notifier).state = 'draft-b';
      await tester.pump();
      await tester.enterText(
        find.byKey(_fieldKey('draft-b', CaseChapterType.background)),
        'De B',
      );
      await tester.pump();

      expect(
        _draftIn(container, 'draft-a').chapters.orderedMeaningful,
        isEmpty,
      );
    });
  });

  group('sin borrador en edición', () {
    testWidgets('renders nothing instead of crashing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(
            _FakeStore(const [CaseDraft(draftId: 'draft-a')]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(caseDraftsProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ChaptersSection())),
        ),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsNothing);
    });
  });
}
