import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/intake_auth.dart';

/// Sesión del formulario de alta, sobreescribible en tests.
final intakeAuthProvider = Provider<IntakeAuth>((ref) => SupabaseIntakeAuth());

/// Cuenta con la que se ha entrado, o `null` si no hay sesión.
final intakeAccountProvider = StreamProvider<IntakeAccount?>(
  (ref) => ref.watch(intakeAuthProvider).accountChanges(),
);
