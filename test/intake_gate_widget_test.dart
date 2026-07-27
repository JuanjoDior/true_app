import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/presentation/intake/intake_gate_screen.dart';

void main() {
  Future<ProviderContainer> pumpGate(WidgetTester tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(home: IntakeGateScreen());
          },
        ),
      ),
    );
    return container;
  }

  testWidgets('wrong key keeps the gate hidden and shows an error',
      (tester) async {
    final container = await pumpGate(tester);

    await tester.enterText(
      find.byKey(const Key('intake-gate-key-field')),
      'clave-incorrecta',
    );
    await tester.tap(find.byKey(const Key('intake-gate-submit')));
    await tester.pump();

    expect(find.byKey(const Key('intake-gate-error')), findsOneWidget);
    expect(container.read(intakeUnlockedProvider), isFalse);
  });

  testWidgets('correct key unlocks the form with no other lockout',
      (tester) async {
    final container = await pumpGate(tester);

    await tester.enterText(
      find.byKey(const Key('intake-gate-key-field')),
      kIntakeSharedKey,
    );
    await tester.tap(find.byKey(const Key('intake-gate-submit')));
    await tester.pump();

    expect(container.read(intakeUnlockedProvider), isTrue);
    expect(find.byKey(const Key('intake-gate-error')), findsNothing);
  });

  testWidgets('repeated wrong attempts do not trigger a lockout',
      (tester) async {
    final container = await pumpGate(tester);

    for (var i = 0; i < 3; i++) {
      await tester.enterText(
        find.byKey(const Key('intake-gate-key-field')),
        'wrong-$i',
      );
      await tester.tap(find.byKey(const Key('intake-gate-submit')));
      await tester.pump();
    }

    // La clave sigue siendo intentable: no hay bloqueo tras varios fallos.
    await tester.enterText(
      find.byKey(const Key('intake-gate-key-field')),
      kIntakeSharedKey,
    );
    await tester.tap(find.byKey(const Key('intake-gate-submit')));
    await tester.pump();

    expect(container.read(intakeUnlockedProvider), isTrue);
  });
}
