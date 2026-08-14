import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';

/// Los capítulos entran en `CaseDraft` de forma aditiva: los borradores ya
/// guardados no tienen el miembro y deben seguir cargando
/// [spec: case-editorial-chapters, Draft Persistence and Live Preview].
void main() {
  group('borrador heredado', () {
    test('a draft JSON without the member decodes to empty chapters', () {
      final draft = CaseDraft.fromJson(const {
        'draftId': 'draft-a',
        'title': 'Un caso',
      });

      expect(draft.chapters.orderedMeaningful, isEmpty);
    });

    test('a draft JSON without the member keeps its existing fields', () {
      final draft = CaseDraft.fromJson(const {
        'draftId': 'draft-a',
        'title': 'Un caso',
        'year': 1970,
      });

      expect(draft.title, 'Un caso');
    });

    test('a draft built without chapters starts empty', () {
      const draft = CaseDraft(draftId: 'draft-a');

      expect(draft.chapters.orderedMeaningful, isEmpty);
    });
  });

  group('ida y vuelta', () {
    test('chapters survive toJson and fromJson', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: 'Antes', currentStatus: 'Ahora'),
      );

      final restored = CaseDraft.fromJson(draft.toJson());

      expect(
        restored.chapters.orderedMeaningful.map((chapter) => chapter.content),
        orderedEquals(const ['Antes', 'Ahora']),
      );
    });

    test('a round trip preserves the other draft fields', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        title: 'Un caso',
        year: 1970,
        chapters: CaseChapters(background: 'Antes'),
      );

      final restored = CaseDraft.fromJson(draft.toJson());

      expect(restored.year, 1970);
    });
  });

  group('transformaciones que reconstruyen el borrador', () {
    // `withResolvedPlace` no usa `copyWith`: reconstruye el borrador campo a
    // campo, así que olvidar uno lo borra en silencio. Resolver la ubicación
    // en el mapa no debe costarle a nadie los capítulos que ya escribió.
    test('withResolvedPlace keeps the chapters', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: 'Antes'),
      );

      final moved = draft.withResolvedPlace(
        const ResolvedPlace(
          country: 'Noruega',
          countryCode: 'NO',
          regionOrCity: 'Bergen',
        ),
      );

      expect(moved.chapters.contentFor(CaseChapterType.background), 'Antes');
    });

    test('copyWith keeps the chapters when none is passed', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(events: 'Hechos'),
      );

      expect(
        draft
            .copyWith(title: 'Otro')
            .chapters
            .contentFor(CaseChapterType.events),
        'Hechos',
      );
    });

    test('copyWith replaces the chapters when one is passed', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(events: 'Hechos'),
      );

      final updated = draft.copyWith(
        chapters: const CaseChapters(background: 'Antes'),
      );

      expect(updated.chapters.contentFor(CaseChapterType.events), isNull);
    });
  });

  group('omisión al serializar', () {
    test('toJson omits the member when no chapter is meaningful', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: '   '),
      );

      expect(draft.toJson().containsKey('chapters'), isFalse);
    });

    test('toJson omits the member for a draft with no chapters at all', () {
      const draft = CaseDraft(draftId: 'draft-a');

      expect(draft.toJson().containsKey('chapters'), isFalse);
    });

    test('toJson includes the member when a chapter is meaningful', () {
      const draft = CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(events: 'Hechos'),
      );

      expect(draft.toJson()['chapters'], hasLength(1));
    });
  });
}
