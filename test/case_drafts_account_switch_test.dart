import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/application/draft_submission_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/draft_submission.dart';

import 'test_support/fake_intake_auth.dart';

/// Local drafts belong to this device, not to the active sign-in session.
Future<void> _waitForAccount(ProviderContainer container, String? id) async {
  final current = container.read(intakeAccountProvider);
  if (current.hasValue && current.value?.id == id) return;
  final changed = Completer<void>();
  final subscription = container.listen(intakeAccountProvider, (_, next) {
    if (next.hasValue && next.value?.id == id && !changed.isCompleted) {
      changed.complete();
    }
  }, fireImmediately: true);
  try {
    await changed.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        final current = container.read(intakeAccountProvider);
        throw StateError(
          'Timed out waiting for account $id; current state: $current.',
        );
      },
    );
  } finally {
    subscription.close();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('signed in and signed out use the same local store', () async {
    final auth = FakeIntakeAuth();
    final container = ProviderContainer(
      overrides: [intakeAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    final accountSubscription = container.listen(
      intakeAccountProvider,
      (_, _) {},
    );
    addTearDown(accountSubscription.close);
    await Future<void>.delayed(Duration.zero);
    final subscription = container.listen(caseDraftsStoreProvider, (_, _) {});
    addTearDown(subscription.close);
    final store = subscription.read();

    expect(store, isA<SharedPreferencesCaseDraftsStore>());
    await auth.signIn(email: 'ivan@example.com', password: 'x');
    await _waitForAccount(container, 'user-ivan');
    expect(subscription.read(), same(store));

    await auth.signOut();
    await _waitForAccount(container, null);
    expect(subscription.read(), same(store));
  });

  test('local edits do not POST, PATCH, or DELETE to Supabase', () async {
    final auth = FakeIntakeAuth.signedIn();
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        '{"status":"in_review","submitted_at":"2026-09-29T10:00:00+00:00"}',
        200,
      );
    });
    final container = ProviderContainer(
      overrides: [
        intakeAuthProvider.overrideWithValue(auth),
        caseDraftsHttpClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });
    await _waitForAccount(container, 'user-ivan');
    await container.read(caseDraftsProvider.future);
    final notifier = container.read(caseDraftsProvider.notifier);

    final keptDraftId = await notifier.createDraft(
      now: DateTime.utc(2026, 9, 28),
    );
    await notifier.editDraft(
      keptDraftId,
      (draft) => draft.copyWith(title: 'Edición sólo local'),
    );
    final removedDraftId = await notifier.createDraft(
      now: DateTime.utc(2026, 9, 29),
    );
    await notifier.deleteDraft(removedDraftId);
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(requests, isEmpty);

    // Contraste: el mismo cliente y la misma sesión sí hacen la petición
    // cuando se envía a revisión.
    await container
        .read(draftSubmissionServiceProvider)
        .send(
          DraftSubmission.begin(
            submittableTestDraft(draftId: keptDraftId),
            accountId: kTestAccount.id,
          ),
        );
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
  });

  test(
    'local drafts survive sign-out and a different sign-in on this device',
    () async {
      final auth = FakeIntakeAuth();
      final container = ProviderContainer(
        overrides: [intakeAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      await container.read(caseDraftsProvider.future);
      final notifier = container.read(caseDraftsProvider.notifier);
      final draftId = await notifier.createDraft(
        now: DateTime.utc(2026, 9, 28),
      );
      await notifier.editDraft(
        draftId,
        (draft) => draft.copyWith(title: 'Borrador del dispositivo'),
      );

      await auth.signIn(email: 'ivan@example.com', password: 'x');
      await _waitForAccount(container, 'user-ivan');
      container.invalidate(caseDraftsProvider);
      var drafts = await container.read(caseDraftsProvider.future);
      expect(drafts.single.title, 'Borrador del dispositivo');

      await auth.signOut();
      await _waitForAccount(container, null);
      container.invalidate(caseDraftsProvider);
      drafts = await container.read(caseDraftsProvider.future);
      expect(drafts.single.title, 'Borrador del dispositivo');

      await auth.signIn(email: 'berta@example.com', password: 'x');
      await _waitForAccount(container, 'user-berta');
      container.invalidate(caseDraftsProvider);
      drafts = await container.read(caseDraftsProvider.future);
      expect(drafts.single.title, 'Borrador del dispositivo');
    },
  );
}
