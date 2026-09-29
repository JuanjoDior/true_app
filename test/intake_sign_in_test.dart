import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, AuthRetryableFetchException;
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/intake_auth.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

import 'test_support/fake_intake_auth.dart';
import 'test_support/sample_cases.dart';

class _MemoryDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const [
    CaseDraft(draftId: 'draft-a', title: 'Caso A'),
  ];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => saved = drafts;
}

class _SwitchableIntakeAuth implements IntakeAuth {
  _SwitchableIntakeAuth(IntakeAccount account)
    : _initialAccount = account,
      _account = account;

  final IntakeAccount _initialAccount;
  IntakeAccount? _account;

  void switchTo(IntakeAccount account) => _account = account;

  @override
  Stream<IntakeAccount?> accountChanges() => Stream.value(_initialAccount);

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<String?> accessToken() async =>
      _account == null ? null : 'token-${_account!.id}';

  @override
  Future<String?> accessTokenForAccount(String accountId) async =>
      _account?.id == accountId ? 'token-$accountId' : null;
}

class _BrokenAuth implements IntakeAuth {
  int subscriptions = 0;

  @override
  Stream<IntakeAccount?> accountChanges() {
    subscriptions++;
    return Stream.error(Exception('sin red'));
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<String?> accessTokenForAccount(String accountId) =>
      throw UnimplementedError();

  @override
  Future<String?> accessToken() => throw UnimplementedError();
}

Future<void> _waitForAccount(ProviderContainer container, String? id) async {
  if (container.read(intakeAccountProvider).value?.id == id) return;
  final changed = Completer<void>();
  final subscription = container.listen(intakeAccountProvider, (_, next) {
    if (next.value?.id == id && !changed.isCompleted) changed.complete();
  }, fireImmediately: true);
  try {
    await changed.future.timeout(const Duration(seconds: 2));
  } finally {
    subscription.close();
  }
}

Future<void> _pumpIntake(WidgetTester tester, IntakeAuth auth) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        intakeAuthProvider.overrideWithValue(auth),
        caseDraftsStoreProvider.overrideWithValue(_MemoryDraftsStore()),
        casesRepositoryProvider.overrideWithValue(
          const FakeCasesRepository([]),
        ),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
      ],
      // Sin reintento automático: cada intento sale del botón.
      retry: (_, _) => null,
      child: const MaterialApp(home: IntakeWorkspaceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpOfflineIntake(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        intakeAuthProvider.overrideWithValue(FakeIntakeAuth()),
        casesRepositoryProvider.overrideWithValue(
          const FakeCasesRepository([]),
        ),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
      ],
      retry: (_, _) => null,
      child: const MaterialApp(home: IntakeWorkspaceScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _signIn(
  WidgetTester tester, {
  String email = 'ivan@example.com',
  String password = 'secreto-largo',
}) async {
  if (find.byKey(const Key('intake-signin-open')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('intake-signin-open')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const Key('intake-signin-email')), email);
  await tester.enterText(
    find.byKey(const Key('intake-signin-password')),
    password,
  );
  await tester.tap(find.byKey(const Key('intake-signin-submit')));
  await tester.pump();
  await tester.pump();
}

final _form = find.byKey(const Key('intake-draft-item-draft-a'));
final _signInScreen = find.byKey(const Key('intake-signin-submit'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('intake auth token scoping', () {
    test('tokens are available only to their matching account', () async {
      final auth = FakeIntakeAuth.signedIn();

      expect(
        await auth.accessTokenForAccount(kTestAccount.id),
        'token-user-ivan',
      );
      expect(await auth.accessTokenForAccount('user-berta'), isNull);

      await auth.signIn(email: 'berta@example.com', password: 'x');

      expect(await auth.accessTokenForAccount(kTestAccount.id), isNull);
      expect(
        await auth.accessTokenForAccount('user-berta'),
        'token-user-berta',
      );
    });

    test('signing in keeps the local store and sends no draft request', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = FakeIntakeAuth();
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('', 200);
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
      final store = container.read(caseDraftsStoreProvider);
      expect(store, isA<SharedPreferencesCaseDraftsStore>());

      await store.saveDrafts(const [
        CaseDraft(draftId: 'draft-local', title: 'Sólo local'),
      ]);
      await auth.signIn(email: 'ivan@example.com', password: 'x');
      await _waitForAccount(container, kTestAccount.id);

      expect(container.read(caseDraftsStoreProvider), same(store));
      expect((await store.loadDrafts()).single.title, 'Sólo local');
      expect(requests, isEmpty);
    });

    test(
      'an account A store sends no request after auth switches to B',
      () async {
        SharedPreferences.setMockInitialValues({
          'truecrime.case_drafts.user-ivan': jsonEncode({
            'schemaVersion': 1,
            'drafts': [
              {'draftId': 'draft-ivan', 'title': 'Sólo de Iván'},
            ],
            'pendingUpserts': ['draft-ivan'],
            'pendingDeletes': <String>[],
            'remoteIds': <String>[],
          }),
        });
        final auth = _SwitchableIntakeAuth(kTestAccount);
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          return request.method == 'GET'
              ? http.Response('[]', 200)
              : http.Response('', 201);
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
        await _waitForAccount(container, kTestAccount.id);
        final accountAStore = container.read(caseDraftsStoreProvider);

        auth.switchTo(
          const IntakeAccount(id: 'user-berta', email: 'berta@example.com'),
        );
        await accountAStore.loadDrafts();
        await Future<void>.delayed(const Duration(milliseconds: 1200));

        expect(requests, isEmpty);
      },
    );
  });

  group('Intake sign-in', () {
    testWidgets('legacy local drafts are available before signing in', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-legacy', 'title': 'Borrador del navegador'},
          ],
        }),
      });
      await _pumpOfflineIntake(tester);

      expect(
        find.byKey(const Key('intake-draft-item-draft-legacy')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('drafts-backup-button')), findsOneWidget);
      expect(find.byKey(const Key('intake-local-drafts-status')), findsOneWidget);
      expect(find.byKey(const Key('intake-signin-open')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('intake-draft-item-draft-legacy')),
      );
      await tester.pump();
      expect(find.byKey(const Key('intake-export-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('intake-signin-open')));
      await tester.pumpAndSettle();
      expect(_signInScreen, findsOneWidget);
      expect(
        find.byKey(const Key('intake-draft-item-draft-legacy')),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('truecrime.case_drafts'), isNotNull);
    });

    testWidgets('a remembered session opens the form directly', (tester) async {
      await _pumpIntake(tester, FakeIntakeAuth.signedIn());

      expect(_form, findsOneWidget);
      expect(_signInScreen, findsNothing);
      expect(find.text('ivan@example.com'), findsOneWidget);
    });

    testWidgets('signing in sends the trimmed e-mail and opens the form', (
      tester,
    ) async {
      final auth = FakeIntakeAuth();
      await _pumpIntake(tester, auth);

      await _signIn(tester, email: '  ivan@example.com ');

      expect(auth.signInCalls.single.email, 'ivan@example.com');
      expect(auth.signInCalls.single.password, 'secreto-largo');
      expect(_form, findsOneWidget);
    });

    testWidgets('wrong credentials keep the sign-in and say so', (
      tester,
    ) async {
      final auth = FakeIntakeAuth()
        ..signInError = const AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        );
      await _pumpIntake(tester, auth);

      await _signIn(tester);

      expect(
        find.text('El email o la contraseña no son correctos.'),
        findsOneWidget,
      );
      expect(_form, findsOneWidget);
    });

    testWidgets('empty fields are caught before asking Supabase', (
      tester,
    ) async {
      final auth = FakeIntakeAuth();
      await _pumpIntake(tester, auth);

      await _signIn(tester, email: ' ', password: '');

      expect(auth.signInCalls, isEmpty);
      expect(find.text('Escribe tu email y tu contraseña.'), findsOneWidget);
    });

    testWidgets('while signing in the button cannot be pressed twice', (
      tester,
    ) async {
      final auth = FakeIntakeAuth()..signInGate = Completer<void>();
      await _pumpIntake(tester, auth);

      await _signIn(tester);
      final button = tester.widget<ElevatedButton>(_signInScreen);
      expect(button.onPressed, isNull);
      expect(find.text('Entrando…'), findsOneWidget);

      auth.signInGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(auth.signInCalls, hasLength(1));
      expect(_form, findsOneWidget);
    });

    testWidgets('a sign-in that never answers gives up and says so', (
      tester,
    ) async {
      final auth = FakeIntakeAuth()..signInGate = Completer<void>();
      await _pumpIntake(tester, auth);

      await _signIn(tester);
      await tester.pump(kIntakeSignInTimeout);
      await tester.pump();

      expect(
        find.text('No se pudo conectar. Revisa la conexión y vuelve a probar.'),
        findsOneWidget,
      );
      final button = tester.widget<ElevatedButton>(_signInScreen);
      expect(button.onPressed, isNotNull);
      expect(_form, findsOneWidget);
    });

    testWidgets('signing out returns to the sign-in', (tester) async {
      final auth = FakeIntakeAuth.signedIn();
      await _pumpIntake(tester, auth);

      await tester.tap(find.byKey(const Key('intake-signout-button')));
      await tester.pump();
      await tester.pump();

      expect(auth.signOutCalls, 1);
      expect(find.byKey(const Key('intake-signin-open')), findsOneWidget);
      expect(_form, findsOneWidget);
    });

    testWidgets('a failed sign-out keeps the form and says so', (tester) async {
      final auth = FakeIntakeAuth.signedIn()
        ..signOutError = AuthRetryableFetchException();
      await _pumpIntake(tester, auth);

      await tester.tap(find.byKey(const Key('intake-signout-button')));
      await tester.pump();
      await tester.pump();

      expect(auth.signOutCalls, 1);
      expect(
        find.text('No se pudo cerrar la sesión. Vuelve a probar.'),
        findsOneWidget,
      );
      expect(_form, findsOneWidget);
    });

    testWidgets('if the session cannot be checked, local drafting remains open', (
      tester,
    ) async {
      final auth = _BrokenAuth();
      await _pumpIntake(tester, auth);

      expect(_form, findsOneWidget);
      expect(find.byKey(const Key('intake-signin-open')), findsOneWidget);
      expect(auth.subscriptions, 1);
    });
  });

  group('describeSignInError', () {
    test('wrong e-mail or password', () {
      expect(
        describeSignInError(
          const AuthApiException(
            'x',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        'El email o la contraseña no son correctos.',
      );
    });

    test('too many attempts', () {
      expect(
        describeSignInError(
          const AuthApiException(
            'x',
            statusCode: '429',
            code: 'over_request_rate_limit',
          ),
        ),
        'Demasiados intentos seguidos. Espera unos minutos y vuelve a probar.',
      );
    });

    test('no connection', () {
      expect(
        describeSignInError(AuthRetryableFetchException()),
        'No se pudo conectar. Revisa la conexión y vuelve a probar.',
      );
    });

    test('no answer in time', () {
      expect(
        describeSignInError(TimeoutException(null)),
        'No se pudo conectar. Revisa la conexión y vuelve a probar.',
      );
    });

    test('anything else never leaks a raw error', () {
      expect(
        describeSignInError(StateError('boom')),
        'No se pudo entrar. Vuelve a probar en un momento.',
      );
    });
  });
}
