import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/draft_validator.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

void main() {
  test('rejects a draft missing all required fields', () {
    const draft = CaseDraft(draftId: 'draft-1');

    final result = validateDraft(draft);

    expect(result.isValid, isFalse);
    expect(result.titleError, isNotNull);
    expect(result.categoryError, isNotNull);
    expect(result.yearError, isNotNull);
    expect(result.statusError, isNotNull);
  });

  test('accepts a draft with all required fields filled', () {
    const draft = CaseDraft(
      draftId: 'draft-2',
      title: 'Caso completo',
      category: CaseCategory.unsolved,
      year: 2001,
      status: CaseStatus.open,
    );

    final result = validateDraft(draft);

    expect(result.isValid, isTrue);
    expect(result.titleError, isNull);
    expect(result.categoryError, isNull);
    expect(result.yearError, isNull);
    expect(result.statusError, isNull);
  });

  test('flags a malformed link without blocking the rest of the draft', () {
    const draft = CaseDraft(
      draftId: 'draft-3',
      title: 'Caso completo',
      category: CaseCategory.unsolved,
      year: 2001,
      status: CaseStatus.open,
      links: [
        DraftLink(title: 'Nota', url: 'no es una url', kind: 'investigation'),
      ],
    );

    final result = validateDraft(draft);

    expect(result.isValid, isTrue);
    expect(result.hasLinkWarnings, isTrue);
    expect(result.linkErrors.first, isNotNull);
  });

  test('does not flag a well-formed link', () {
    const draft = CaseDraft(
      draftId: 'draft-4',
      title: 'Caso completo',
      category: CaseCategory.unsolved,
      year: 2001,
      status: CaseStatus.open,
      links: [
        DraftLink(
          title: 'Fuente',
          url: 'https://example.com',
          kind: 'investigation',
        ),
      ],
    );

    final result = validateDraft(draft);

    expect(result.hasLinkWarnings, isFalse);
    expect(result.linkErrors.first, isNull);
  });
}
