import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

void main() {
  test('round-trips a fully filled draft through JSON', () {
    const draft = CaseDraft(
      draftId: 'draft-1',
      title: 'Caso de prueba',
      category: CaseCategory.unsolved,
      year: 1994,
      status: CaseStatus.open,
      summary: 'Resumen del caso',
      links: [
        DraftLink(
          title: 'Wikipedia',
          url: 'https://example.com',
          kind: 'investigation',
        ),
      ],
    );

    final json = draft.toJson();
    final restored = CaseDraft.fromJson(json);

    expect(restored.draftId, 'draft-1');
    expect(restored.title, 'Caso de prueba');
    expect(restored.category, CaseCategory.unsolved);
    expect(restored.year, 1994);
    expect(restored.status, CaseStatus.open);
    expect(restored.summary, 'Resumen del caso');
    expect(restored.links, hasLength(1));
    expect(restored.links.first.title, 'Wikipedia');
    expect(restored.links.first.url, 'https://example.com');
    expect(restored.links.first.kind, 'investigation');
  });

  test('applies tolerant defaults when fields are missing from the payload', () {
    final restored = CaseDraft.fromJson({'draftId': 'draft-2'});

    expect(restored.draftId, 'draft-2');
    expect(restored.title, isNull);
    expect(restored.category, isNull);
    expect(restored.year, isNull);
    expect(restored.status, isNull);
    expect(restored.summary, isNull);
    expect(restored.links, isEmpty);
  });
}
