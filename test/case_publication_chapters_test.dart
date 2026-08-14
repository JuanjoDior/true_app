import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_exporter.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

/// Los capítulos cruzan el puente borrador → JSON de catálogo → caso publicado
/// [spec: case-editorial-chapters, Publication Round Trip].
///
/// Un test por afirmación: con varios `expect` juntos el primero que falla
/// esconde a los demás.
CaseDraft _publishable({CaseChapters chapters = const CaseChapters()}) {
  return CaseDraft(
    draftId: 'draft-a',
    title: 'La mujer de Isdal',
    category: CaseCategory.unsolved,
    year: 1970,
    country: 'Noruega',
    countryCode: 'no',
    regionOrCity: 'Bergen',
    latitude: 60.39,
    longitude: 5.32,
    summary: 'Un cuerpo sin nombre en el valle de Isdalen.',
    chapters: chapters,
  );
}

void main() {
  group('draftToCaseJson — forma exportada', () {
    test('omits the member when no chapter is meaningful', () {
      final json = draftToCaseJson(
        _publishable(chapters: const CaseChapters(background: '   ')),
      );

      expect(json.containsKey('chapters'), isFalse);
    });

    test('omits the member for a draft with no chapters at all', () {
      expect(draftToCaseJson(_publishable()).containsKey('chapters'), isFalse);
    });

    test('exports only the meaningful chapters', () {
      final json = draftToCaseJson(
        _publishable(
          chapters: const CaseChapters(background: 'Antes', events: '  '),
        ),
      );

      expect(json['chapters'], hasLength(1));
    });

    test('exports them in editorial order, not authoring order', () {
      final json = draftToCaseJson(
        _publishable(
          chapters: const CaseChapters(
            currentStatus: 'Ahora',
            background: 'Antes',
          ),
        ),
      );

      expect(
        (json['chapters'] as List).map((entry) => entry['type']),
        orderedEquals(const ['background', 'currentStatus']),
      );
    });

    // Todo lo demás que exporta el borrador se recorta. Los capítulos no: son
    // prosa editorial y su sangría es intencionada [diseño §4.3].
    test(
      'preserves chapter content verbatim while other fields are trimmed',
      () {
        const authored = '  Primera línea.\n\n  Con sangría.  ';
        final json = draftToCaseJson(
          _publishable(chapters: const CaseChapters(investigation: authored)),
        );

        expect((json['chapters'] as List).single['content'], authored);
      },
    );

    test('still trims the summary, so the exception is only for chapters', () {
      final draft = CaseDraft(
        draftId: 'draft-a',
        title: 'Un caso',
        summary: '  Con espacios  ',
        chapters: const CaseChapters(background: '  Con espacios  '),
      );

      expect(draftToCaseJson(draft)['summary'], 'Con espacios');
    });
  });

  group('ida y vuelta hasta el caso publicado', () {
    test('a published case decodes the exported chapters', () {
      final json = draftToCaseJson(
        _publishable(
          chapters: const CaseChapters(
            background: 'Antes',
            events: 'Hechos',
            investigation: 'Pistas',
            currentStatus: 'Ahora',
          ),
        ),
      );

      final published = TrueCrimeCase.fromJson(json);

      expect(
        published.chapters.orderedMeaningful.map((chapter) => chapter.content),
        orderedEquals(const ['Antes', 'Hechos', 'Pistas', 'Ahora']),
      );
    });

    test('a published case keeps the verbatim content across the bridge', () {
      const authored = '  Sangría conservada.  ';
      final published = TrueCrimeCase.fromJson(
        draftToCaseJson(
          _publishable(chapters: const CaseChapters(events: authored)),
        ),
      );

      expect(published.chapters.contentFor(CaseChapterType.events), authored);
    });

    test('a published case without the member has no chapters', () {
      final published = TrueCrimeCase.fromJson(draftToCaseJson(_publishable()));

      expect(published.chapters.orderedMeaningful, isEmpty);
    });
  });
}
