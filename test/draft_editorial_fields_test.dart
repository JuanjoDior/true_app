import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';

void main() {
  group('parseTags', () {
    test('splits a comma-separated line into tags', () {
      expect(parseTags('1960s, ee. uu., sin resolver'),
          ['1960s', 'ee. uu.', 'sin resolver']);
    });

    test('trims spaces and drops the empty pieces', () {
      // Escribir comas de más mientras se teclea no debe crear tags vacíos.
      expect(parseTags('  1960s ,, , ee. uu.  ,'), ['1960s', 'ee. uu.']);
    });

    test('lowercases them to match the catalogue', () {
      // Los 14 casos publicados guardan los tags en minúsculas.
      expect(parseTags('1960s, EE. UU., Sin Resolver'),
          ['1960s', 'ee. uu.', 'sin resolver']);
    });

    test('drops duplicates keeping the first appearance', () {
      expect(parseTags('cifrado, prensa, cifrado'), ['cifrado', 'prensa']);
    });

    test('returns no tags for an empty line', () {
      expect(parseTags(''), isEmpty);
      expect(parseTags('   ,  , '), isEmpty);
    });
  });

  group('formatTags', () {
    test('joins the tags back into an editable line', () {
      expect(formatTags(['1960s', 'ee. uu.']), '1960s, ee. uu.');
    });

    test('round-trips through the text field', () {
      const line = '1960s, ee. uu., cifrado';
      expect(formatTags(parseTags(line)), line);
    });
  });

  group('CaseDraft editorial fields', () {
    test('round-trips victim, tags and timeline through JSON', () {
      const draft = CaseDraft(
        draftId: 'draft-1',
        victim: 'Al menos 5 víctimas confirmadas',
        tags: ['1960s', 'ee. uu.'],
        timeline: [
          DraftTimelineEvent(
            date: '1968–69',
            title: 'Primeros ataques confirmados',
            kind: CaseTimelineKind.initial,
          ),
          DraftTimelineEvent(date: 'Hoy', title: 'Investigación abierta'),
        ],
      );

      final restored = CaseDraft.fromJson(draft.toJson());

      expect(restored.victim, 'Al menos 5 víctimas confirmadas');
      expect(restored.tags, ['1960s', 'ee. uu.']);
      expect(restored.timeline, hasLength(2));
      expect(restored.timeline.first.date, '1968–69');
      expect(restored.timeline.first.title, 'Primeros ataques confirmados');
      expect(restored.timeline.first.kind, CaseTimelineKind.initial);
      // El tipo es opcional mientras se redacta.
      expect(restored.timeline.last.kind, isNull);
    });

    test('loads a draft saved before these fields existed', () {
      final restored = CaseDraft.fromJson({
        'draftId': 'draft-antiguo',
        'title': 'Caso previo',
      });

      expect(restored.victim, isNull);
      expect(restored.tags, isEmpty);
      expect(restored.timeline, isEmpty);
    });

    test('degrades an unknown timeline kind instead of failing to load', () {
      // `CaseTimelineKind.fromJson` lanza ante un valor desconocido; el
      // borrador no puede permitirse que un dato raro lo deje inaccesible.
      final restored = CaseDraft.fromJson({
        'draftId': 'draft-raro',
        'timeline': [
          {'date': '1970', 'title': 'Hito', 'kind': 'inventado'},
          {'date': '1971', 'title': 'Otro', 'kind': 'red'},
        ],
      });

      expect(restored.timeline.first.kind, isNull);
      // `red` es el valor heredado de `initial` y debe conservar su sentido.
      expect(restored.timeline.last.kind, CaseTimelineKind.initial);
    });
  });

  group('CaseTimelineKind labels', () {
    test('every kind has a label for the dropdown', () {
      for (final kind in CaseTimelineKind.values) {
        expect(kind.label, isNotEmpty);
      }
      expect(CaseTimelineKind.initial.label, 'Hecho inicial');
      expect(CaseTimelineKind.solved.label, 'Resolución');
    });
  });
}
