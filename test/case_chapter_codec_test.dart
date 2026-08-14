import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';

/// Contrato del modelo de capítulos editoriales [spec: case-editorial-chapters].
///
/// Los tests son deliberadamente pequeños: con varios `expect` en un mismo
/// `test`, el primero que falla aborta los demás, así que una mutación sólo
/// probaría la primera aserción. Uno por afirmación mantiene honesta la
/// atribución del rojo.
void main() {
  group('CaseChapterType — el conjunto es fijo', () {
    test('exposes exactly four chapter types', () {
      expect(CaseChapterType.values, hasLength(4));
    });

    test('exposes them in the fixed editorial order', () {
      expect(
        CaseChapterType.values,
        orderedEquals(const [
          CaseChapterType.background,
          CaseChapterType.events,
          CaseChapterType.investigation,
          CaseChapterType.currentStatus,
        ]),
      );
    });
  });

  group('orderedMeaningful — orden y significancia', () {
    test(
      'returns chapters in editorial order regardless of assignment order',
      () {
        const chapters = CaseChapters(
          currentStatus: 'Cuarto',
          background: 'Primero',
          investigation: 'Tercero',
          events: 'Segundo',
        );

        expect(
          chapters.orderedMeaningful.map((chapter) => chapter.content),
          orderedEquals(const ['Primero', 'Segundo', 'Tercero', 'Cuarto']),
        );
      },
    );

    test('omits a whitespace-only chapter', () {
      const chapters = CaseChapters(background: '   \n  ', events: 'Real');

      expect(
        chapters.orderedMeaningful.map((chapter) => chapter.type),
        orderedEquals(const [CaseChapterType.events]),
      );
    });

    test('omits an empty chapter', () {
      const chapters = CaseChapters(background: '', events: 'Real');

      expect(
        chapters.orderedMeaningful.map((chapter) => chapter.type),
        orderedEquals(const [CaseChapterType.events]),
      );
    });

    test('is empty when nothing is meaningful', () {
      const chapters = CaseChapters(background: '  ', currentStatus: '');

      expect(chapters.orderedMeaningful, isEmpty);
    });

    test(
      'preserves meaningful content verbatim, including surrounding blanks',
      () {
        const authored = '  Primera línea.\n\n  Segunda línea con sangría.  ';
        const chapters = CaseChapters(background: authored);

        expect(chapters.orderedMeaningful.single.content, authored);
      },
    );
  });

  group('contentFor y withContent', () {
    test('contentFor returns the content of the requested type', () {
      const chapters = CaseChapters(investigation: 'Pistas');

      expect(chapters.contentFor(CaseChapterType.investigation), 'Pistas');
    });

    test('contentFor returns null for an unset type', () {
      const chapters = CaseChapters(investigation: 'Pistas');

      expect(chapters.contentFor(CaseChapterType.events), isNull);
    });

    test('withContent sets the requested slot without touching the others', () {
      const chapters = CaseChapters(background: 'Antes');
      final updated = chapters.withContent(CaseChapterType.events, 'Hechos');

      expect(updated.contentFor(CaseChapterType.background), 'Antes');
    });

    test('withContent stores the new content', () {
      const chapters = CaseChapters(background: 'Antes');
      final updated = chapters.withContent(CaseChapterType.events, 'Hechos');

      expect(updated.contentFor(CaseChapterType.events), 'Hechos');
    });

    test(
      'withContent clears the slot when the new content is whitespace-only',
      () {
        const chapters = CaseChapters(background: 'Antes');
        final updated = chapters.withContent(CaseChapterType.background, '   ');

        expect(updated.orderedMeaningful, isEmpty);
      },
    );

    test('withContent leaves the original untouched', () {
      const chapters = CaseChapters(background: 'Antes');
      chapters.withContent(CaseChapterType.background, 'Después');

      expect(chapters.contentFor(CaseChapterType.background), 'Antes');
    });
  });

  group('fromJson — decodificación tolerante', () {
    test('treats a null member as an empty collection', () {
      expect(CaseChapters.fromJson(null).orderedMeaningful, isEmpty);
    });

    test('treats a non-array value as an empty collection', () {
      expect(CaseChapters.fromJson('capítulos').orderedMeaningful, isEmpty);
    });

    test('decodes a well-formed entry', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'background', 'content': 'Antecedentes'},
      ]);

      expect(chapters.contentFor(CaseChapterType.background), 'Antecedentes');
    });

    test('returns entries in editorial order regardless of input order', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'currentStatus', 'content': 'Ahora'},
        {'type': 'background', 'content': 'Antes'},
      ]);

      expect(
        chapters.orderedMeaningful.map((chapter) => chapter.type),
        orderedEquals(const [
          CaseChapterType.background,
          CaseChapterType.currentStatus,
        ]),
      );
    });

    test('ignores an element that is not an object', () {
      final chapters = CaseChapters.fromJson(const [
        'no soy un objeto',
        {'type': 'events', 'content': 'Hechos'},
      ]);

      expect(chapters.contentFor(CaseChapterType.events), 'Hechos');
    });

    test('ignores an entry whose content is not a string', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'background', 'content': 42},
      ]);

      expect(chapters.orderedMeaningful, isEmpty);
    });

    test('ignores an entry whose type is not a string', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 7, 'content': 'Texto'},
      ]);

      expect(chapters.orderedMeaningful, isEmpty);
    });

    test('ignores an unsupported chapter type', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'epilogue', 'content': 'No existe'},
      ]);

      expect(chapters.orderedMeaningful, isEmpty);
    });

    test('ignores an entry whose content is whitespace-only', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'background', 'content': '   '},
      ]);

      expect(chapters.orderedMeaningful, isEmpty);
    });

    test('keeps the first accepted entry when a type repeats', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'background', 'content': 'Primera'},
        {'type': 'background', 'content': 'Segunda'},
      ]);

      expect(chapters.contentFor(CaseChapterType.background), 'Primera');
    });

    test('a blank earlier entry does not consume its type slot', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'background', 'content': '   '},
        {'type': 'background', 'content': 'Real'},
      ]);

      expect(chapters.contentFor(CaseChapterType.background), 'Real');
    });

    test('a malformed earlier entry does not consume its type slot', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'background', 'content': 99},
        {'type': 'background', 'content': 'Real'},
      ]);

      expect(chapters.contentFor(CaseChapterType.background), 'Real');
    });

    test('ignores extra members instead of letting them override the type', () {
      final chapters = CaseChapters.fromJson(const [
        {
          'type': 'background',
          'content': 'Antes',
          'title': 'Encabezado propio',
        },
      ]);

      expect(chapters.contentFor(CaseChapterType.background), 'Antes');
    });

    test('keeps a valid entry that follows a malformed one', () {
      final chapters = CaseChapters.fromJson(const [
        {'type': 'nope', 'content': 'Ignórame'},
        {'type': 'investigation', 'content': 'Pistas'},
      ]);

      expect(chapters.contentFor(CaseChapterType.investigation), 'Pistas');
    });
  });

  group('toJson — forma de salida', () {
    test('emits nothing when no chapter is meaningful', () {
      const chapters = CaseChapters(background: '   ');

      expect(chapters.toJson(), isEmpty);
    });

    test('emits only meaningful chapters', () {
      const chapters = CaseChapters(background: 'Antes', events: '  ');

      expect(chapters.toJson(), hasLength(1));
    });

    test('emits them in editorial order', () {
      const chapters = CaseChapters(
        currentStatus: 'Ahora',
        background: 'Antes',
      );

      expect(
        chapters.toJson().map((entry) => entry['type']),
        orderedEquals(const ['background', 'currentStatus']),
      );
    });

    test('emits the wire identifier and the verbatim content', () {
      const chapters = CaseChapters(investigation: '  Con sangría  ');

      expect(chapters.toJson().single, const {
        'type': 'investigation',
        'content': '  Con sangría  ',
      });
    });

    test('round-trips through fromJson', () {
      const original = CaseChapters(
        background: 'Antes',
        events: 'Hechos',
        investigation: 'Pistas',
        currentStatus: 'Ahora',
      );

      final restored = CaseChapters.fromJson(original.toJson());

      expect(
        restored.orderedMeaningful.map((chapter) => chapter.content),
        orderedEquals(const ['Antes', 'Hechos', 'Pistas', 'Ahora']),
      );
    });
  });
}
