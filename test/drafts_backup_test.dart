import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/drafts_backup.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

/// La copia de seguridad de los borradores.
///
/// **Lo que importa aquí es el borrador INCOMPLETO.** El exportador de casos ya
/// sabe sacar un caso terminado, pero sólo cuando está terminado; el trabajo de
/// semanas vive precisamente en borradores a medias, y hasta ahora no había
/// forma de sacarlos del navegador. Si un test de este fichero se pone rojo,
/// alguien puede perder meses de investigación.

void main() {
  group('ida y vuelta', () {
    test('an incomplete draft survives the round trip', () {
      // El caso de uso real: un caso recién empezado, con casi todo vacío.
      const draft = CaseDraft(draftId: 'draft-a', title: 'A medias');

      final restored = decodeDraftsBackup(encodeDraftsBackup(const [draft]));

      expect(restored.drafts.single.title, 'A medias');
    });

    test('an empty draft survives too', () {
      const draft = CaseDraft(draftId: 'draft-a');

      final restored = decodeDraftsBackup(encodeDraftsBackup(const [draft]));

      expect(restored.drafts.single.draftId, 'draft-a');
    });

    test('chapters survive the round trip', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: 'Antes', events: 'Hechos'),
      );

      final restored = decodeDraftsBackup(encodeDraftsBackup(const [draft]));

      expect(
        restored.drafts.single.chapters.contentFor(CaseChapterType.background),
        'Antes',
      );
    });

    test('chapter prose keeps its line breaks and indentation', () {
      const authored = '  Primera línea.\n\n  Con sangría.  ';
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(investigation: authored),
      );

      final restored = decodeDraftsBackup(encodeDraftsBackup(const [draft]));

      expect(
        restored.drafts.single.chapters.contentFor(
          CaseChapterType.investigation,
        ),
        authored,
      );
    });

    test('every draft survives, not just the first', () {
      final restored = decodeDraftsBackup(
        encodeDraftsBackup(const [
          CaseDraft(draftId: 'draft-a'),
          CaseDraft(draftId: 'draft-b'),
          CaseDraft(draftId: 'draft-c'),
        ]),
      );

      expect(restored.drafts, hasLength(3));
    });

    test('a filled-in draft keeps its category and year', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        category: CaseCategory.serialKiller,
        year: 1968,
      );

      final restored = decodeDraftsBackup(encodeDraftsBackup(const [draft]));

      expect(restored.drafts.single.year, 1968);
    });

    test('an empty archive round-trips to an empty archive', () {
      final restored = decodeDraftsBackup(encodeDraftsBackup(const []));

      expect(restored.drafts, isEmpty);
    });
  });

  group('un texto que no sirve avisa en vez de romper', () {
    test('plain nonsense is rejected', () {
      expect(decodeDraftsBackup('esto no es json').error, isNotNull);
    });

    test('a rejected text yields no drafts', () {
      // Nunca "medio importado": o entra entero o no entra.
      expect(decodeDraftsBackup('esto no es json').drafts, isEmpty);
    });

    test('valid json that is not a backup envelope is rejected', () {
      expect(decodeDraftsBackup('[1, 2, 3]').error, isNotNull);
    });

    test('an envelope without drafts is rejected', () {
      expect(decodeDraftsBackup('{"schemaVersion": 1}').error, isNotNull);
    });

    test('a newer schema version is rejected rather than half-read', () {
      // Un formato futuro puede significar cosas distintas con las mismas
      // claves. Leerlo a medias es peor que decir que no se puede.
      final result = decodeDraftsBackup(
        '{"schemaVersion": 99, "drafts": [{"draftId": "a"}]}',
      );

      expect(result.error, isNotNull);
    });

    test('a draft without its id is rejected', () {
      final result = decodeDraftsBackup(
        '{"schemaVersion": 1, "drafts": [{"title": "sin id"}]}',
      );

      expect(result.error, isNotNull);
    });

    test('an accepted backup reports no error', () {
      // Gemelo de los de arriba: sin él, "siempre da error" los pasaría todos.
      final result = decodeDraftsBackup(
        encodeDraftsBackup(const [CaseDraft(draftId: 'draft-a')]),
      );

      expect(result.error, isNull);
    });
  });

  group('reponer sin destruir', () {
    test('an incoming draft is added', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a')],
        incoming: const [CaseDraft(draftId: 'draft-b')],
      );

      expect(
        merged.map((draft) => draft.draftId),
        containsAll(const ['draft-a', 'draft-b']),
      );
    });

    test('a draft that only exists locally is kept', () {
      // Restaurar una copia vieja NO puede borrar lo que se hizo después.
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Local')],
        incoming: const [CaseDraft(draftId: 'draft-b')],
      );

      expect(
        merged.firstWhere((draft) => draft.draftId == 'draft-a').title,
        'Local',
      );
    });

    test('the incoming version wins for a draft that exists in both', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Viejo')],
        incoming: const [CaseDraft(draftId: 'draft-a', title: 'De la copia')],
      );

      expect(merged.single.title, 'De la copia');
    });

    test('a draft present in both is not duplicated', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Viejo')],
        incoming: const [CaseDraft(draftId: 'draft-a', title: 'De la copia')],
      );

      expect(merged, hasLength(1));
    });

    test('restoring an empty backup changes nothing', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Local')],
        incoming: const [],
      );

      expect(merged.single.title, 'Local');
    });

    test('restoring into an empty workspace brings everything', () {
      final merged = mergeDrafts(
        current: const [],
        incoming: const [
          CaseDraft(draftId: 'draft-a'),
          CaseDraft(draftId: 'draft-b'),
        ],
      );

      expect(merged, hasLength(2));
    });
  });
}
