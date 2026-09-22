import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';

void main() {
  test('round-trips handoffSlug and handoffAt through JSON', () {
    final at = DateTime.utc(2026, 9, 12, 10, 30);
    final draft = CaseDraft(
      draftId: 'draft-1',
      title: 'Caso de prueba',
      handoffSlug: 'caso-de-prueba',
      handoffAt: at,
    );

    final json = draft.toJson();
    final restored = CaseDraft.fromJson(json);

    expect(restored.handoffSlug, 'caso-de-prueba');
    expect(restored.handoffAt, at);
  });

  test('decodes a missing handoff marker to null', () {
    final restored = CaseDraft.fromJson({'draftId': 'draft-2'});

    expect(restored.handoffSlug, isNull);
    expect(restored.handoffAt, isNull);
  });

  test('decodes a garbage handoffAt string to null instead of throwing', () {
    final restored = CaseDraft.fromJson({
      'draftId': 'draft-3',
      'handoffSlug': 'draft-3-slug',
      'handoffAt': 'no es una fecha',
    });

    expect(restored.handoffSlug, 'draft-3-slug');
    expect(restored.handoffAt, isNull);
  });

  test(
    'markHandedOff followed by copyWith keeps the handoff marker intact',
    () {
      const draft = CaseDraft(draftId: 'draft-4', title: 'Título original');
      final at = DateTime.utc(2026, 9, 12);

      final handedOff = draft.markHandedOff(slug: 'titulo-original', at: at);
      final edited = handedOff.copyWith(title: 'Título editado');

      expect(edited.title, 'Título editado');
      expect(edited.handoffSlug, 'titulo-original');
      expect(edited.handoffAt, at);
    },
  );

  test(
    'markHandedOff followed by withResolvedPlace keeps the handoff marker intact',
    () {
      const draft = CaseDraft(draftId: 'draft-5', title: 'Otro caso');
      final at = DateTime.utc(2026, 9, 12);

      final handedOff = draft.markHandedOff(slug: 'otro-caso', at: at);
      final replaced = handedOff.withResolvedPlace(
        const ResolvedPlace(
          country: 'España',
          countryCode: 'ES',
          regionOrCity: 'Madrid',
        ),
      );

      expect(replaced.country, 'España');
      expect(replaced.handoffSlug, 'otro-caso');
      expect(replaced.handoffAt, at);
    },
  );
}
