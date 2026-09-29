import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

import 'test_support/fake_intake_auth.dart';
import 'test_support/sample_cases.dart';

Future<void> _pumpWorkspace(WidgetTester tester, FakeIntakeAuth auth) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        intakeAuthProvider.overrideWithValue(auth),
        casesRepositoryProvider.overrideWithValue(
          const FakeCasesRepository([]),
        ),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
      ],
      child: const MaterialApp(home: IntakeWorkspaceScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectNoSyncStatus(WidgetTester tester) {
  expect(find.byKey(const Key('intake-sync-status')), findsNothing);
  expect(find.text('Guardando…'), findsNothing);
  expect(find.text('Guardado en la nube'), findsNothing);
  expect(
    find.text('Sin conexión: guardado en este navegador'),
    findsNothing,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'signed-in footer identifies local drafts without cloud status',
    (tester) async {
      await _pumpWorkspace(tester, FakeIntakeAuth.signedIn());

      expect(find.text('ivan@example.com'), findsOneWidget);
      expect(
        find.byKey(const Key('intake-local-drafts-status')),
        findsOneWidget,
      );
      expect(
        find.text('Borradores guardados en este dispositivo'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('intake-signout-button')), findsOneWidget);
      _expectNoSyncStatus(tester);
    },
  );

  testWidgets(
    'signed-out authoring offers local drafts and sign-in',
    (tester) async {
      await _pumpWorkspace(tester, FakeIntakeAuth());

      expect(
        find.text('Borradores guardados en este dispositivo'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('intake-signin-open')), findsOneWidget);
      expect(find.byKey(const Key('drafts-backup-button')), findsOneWidget);
      _expectNoSyncStatus(tester);
    },
  );
}
