import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/data/draft_submission.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

import 'test_support/fake_intake_auth.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('DraftSubmission.begin', () {
    test('freezes the payload exactly as draft.toJson() at that moment', () {
      final draft = submittableTestDraft();
      final submission = DraftSubmission.begin(draft, accountId: 'user-ivan');

      expect(submission.draftId, draft.draftId);
      expect(submission.accountId, 'user-ivan');
      expect(submission.payload, draft.toJson());
    });

    test('later edits of the draft do not change the frozen payload', () {
      final draft = submittableTestDraft();
      final submission = DraftSubmission.begin(draft, accountId: 'user-ivan');
      final edited = draft.copyWith(title: 'Otro título');

      expect(edited.toJson(), isNot(submission.payload));
      expect(submission.payload['title'], draft.title);
    });

    test('the payload cannot be mutated, not even in nested values', () {
      final submission = DraftSubmission.begin(
        submittableTestDraft().copyWith(tags: const ['a']),
        accountId: 'user-ivan',
      );

      expect(() => submission.payload['title'] = 'x', throwsUnsupportedError);
      expect(
        () => (submission.payload['tags'] as List).add('b'),
        throwsUnsupportedError,
      );
    });

    test('generates a lowercase v4 UUID, different for each intention', () {
      final draft = submittableTestDraft();
      final ids = {
        for (var i = 0; i < 50; i++)
          DraftSubmission.begin(draft, accountId: 'user-ivan').submissionId,
      };

      expect(ids, hasLength(50));
      expect(ids.every(_uuidV4.hasMatch), isTrue);
    });

    test('accepts an injected id generator', () {
      final submission = DraftSubmission.begin(
        submittableTestDraft(),
        accountId: 'user-ivan',
        newSubmissionId: () => 'fixed-id',
      );

      expect(submission.submissionId, 'fixed-id');
    });

    test('rejects an invalid draft without generating an id', () {
      var generated = 0;

      expect(
        () => DraftSubmission.begin(
          const CaseDraft(draftId: 'draft-vacio'),
          accountId: 'user-ivan',
          newSubmissionId: () {
            generated++;
            return 'x';
          },
        ),
        throwsA(isA<SubmissionInvalidDraftException>()),
      );
      expect(generated, 0);
    });
  });
}
