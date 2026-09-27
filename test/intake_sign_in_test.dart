import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> _signIn(
  WidgetTester tester, {
  String email = 'ivan@example.com',
  String password = 'secreto-largo',
}) async {
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
  group('Intake sign-in', () {
    testWidgets('without a session the form stays hidden behind the sign-in', (
      tester,
    ) async {
      await _pumpIntake(tester, FakeIntakeAuth());

      expect(_signInScreen, findsOneWidget);
      expect(_form, findsNothing);
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
      expect(_form, findsNothing);
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

    testWidgets('signing out returns to the sign-in', (tester) async {
      final auth = FakeIntakeAuth.signedIn();
      await _pumpIntake(tester, auth);

      await tester.tap(find.byKey(const Key('intake-signout-button')));
      await tester.pump();
      await tester.pump();

      expect(auth.signOutCalls, 1);
      expect(_signInScreen, findsOneWidget);
      expect(_form, findsNothing);
    });

    testWidgets('if the session cannot be checked, it says so and retries', (
      tester,
    ) async {
      final auth = _BrokenAuth();
      await _pumpIntake(tester, auth);

      expect(find.byKey(const Key('intake-session-error')), findsOneWidget);
      expect(_signInScreen, findsNothing);
      expect(_form, findsNothing);

      await tester.tap(find.byKey(const Key('intake-session-retry')));
      await tester.pump();
      await tester.pump();
      expect(auth.subscriptions, 2);
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

    test('anything else never leaks a raw error', () {
      expect(
        describeSignInError(StateError('boom')),
        'No se pudo entrar. Vuelve a probar en un momento.',
      );
    });
  });
}
