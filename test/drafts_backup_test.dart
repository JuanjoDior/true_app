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
        merged.drafts.map((draft) => draft.draftId),
        containsAll(const ['draft-a', 'draft-b']),
      );
      expect(merged.added, 1);
      expect(merged.keptLocal, 0);
    });

    test('a draft that only exists locally is kept', () {
      // Restaurar una copia vieja NO puede borrar lo que se hizo después.
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Local')],
        incoming: const [CaseDraft(draftId: 'draft-b')],
      );

      expect(
        merged.drafts.firstWhere((draft) => draft.draftId == 'draft-a').title,
        'Local',
      );
    });

    test('the local version wins for a draft that exists in both', () {
      // Una copia vieja del navegador no puede deshacer lo editado después
      // en este equipo.
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Local')],
        incoming: const [CaseDraft(draftId: 'draft-a', title: 'De la copia')],
      );

      expect(merged.drafts.single.title, 'Local');
    });

    test('a different version of a local draft is reported, not added', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Local')],
        incoming: const [CaseDraft(draftId: 'draft-a', title: 'De la copia')],
      );

      expect(merged.keptLocal, 1);
      expect(merged.added, 0);
    });

    test('an identical copy of a local draft is not a conflict', () {
      // Gemelo del anterior: sin él, "todo lo que coincide es conflicto" lo
      // pasaría.
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Igual')],
        incoming: const [CaseDraft(draftId: 'draft-a', title: 'Igual')],
      );

      expect(merged.keptLocal, 0);
      expect(merged.added, 0);
      expect(merged.drafts.single.title, 'Igual');
    });

    test('identical content is compared deeply, not by reference', () {
      // Dos borradores leídos por separado nunca son el mismo objeto; lo que
      // cuenta es el contenido, incluidas las listas anidadas.
      final local = decodeDraftsBackup(
        encodeDraftsBackup([_completeDraft()]),
      ).drafts;
      final incoming = decodeDraftsBackup(
        encodeDraftsBackup([_completeDraft()]),
      ).drafts;

      final merged = mergeDrafts(current: local, incoming: incoming);

      expect(merged.keptLocal, 0);
    });

    test('a difference deep inside a draft is still a conflict', () {
      final local = _completeDraft();
      final incoming = local.copyWith(
        timeline: const [
          DraftTimelineEvent(date: '1968-12-20', title: 'Otro título'),
        ],
      );

      final merged = mergeDrafts(current: [local], incoming: [incoming]);

      expect(merged.keptLocal, 1);
      expect(merged.drafts.single.toJson(), local.toJson());
    });

    test('a draft present in both is not duplicated', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Viejo')],
        incoming: const [CaseDraft(draftId: 'draft-a', title: 'De la copia')],
      );

      expect(merged.drafts, hasLength(1));
    });

    test('restoring an empty backup changes nothing', () {
      final merged = mergeDrafts(
        current: const [CaseDraft(draftId: 'draft-a', title: 'Local')],
        incoming: const [],
      );

      expect(merged.drafts.single.title, 'Local');
      expect(merged.added, 0);
      expect(merged.keptLocal, 0);
    });

    test('restoring into an empty workspace brings everything', () {
      final merged = mergeDrafts(
        current: const [],
        incoming: const [
          CaseDraft(draftId: 'draft-a'),
          CaseDraft(draftId: 'draft-b'),
        ],
      );

      expect(merged.drafts, hasLength(2));
      expect(merged.added, 2);
    });
  });
}

/// Borrador con listas y capítulos rellenos, para comparar a fondo.
CaseDraft _completeDraft() {
  return const CaseDraft(
    draftId: 'draft-a',
    title: 'Caso completo',
    category: CaseCategory.serialKiller,
    year: 1968,
    tags: ['1960s', 'ee. uu.'],
    timeline: [DraftTimelineEvent(date: '1968-12-20', title: 'Primer crimen')],
    links: [DraftLink(url: 'https://example.com/podcast')],
    photos: [DraftPhoto(url: 'https://example.com/foto.jpg', caption: 'Pie')],
    chapters: CaseChapters(background: 'Antes', events: 'Hechos'),
  );
}
