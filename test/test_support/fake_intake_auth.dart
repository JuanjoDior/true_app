import 'dart:async';

import 'package:true_app/features/cases/data/intake_auth.dart';

const kTestAccount = IntakeAccount(id: 'user-ivan', email: 'ivan@example.com');

/// Sesión en memoria para los tests del formulario: nada sale a Supabase.
class FakeIntakeAuth implements IntakeAuth {
  FakeIntakeAuth({IntakeAccount? account}) : _account = account;

  /// Ya dentro, que es lo que necesitan los tests del formulario en sí.
  FakeIntakeAuth.signedIn() : this(account: kTestAccount);

  IntakeAccount? _account;
  final _changes = StreamController<IntakeAccount?>.broadcast();

  final signInCalls = <({String email, String password})>[];
  int signOutCalls = 0;

  /// Si se fija, `signIn` falla con esto en vez de entrar.
  Object? signInError;

  /// Si se fija, `signIn` espera a que se complete antes de responder.
  Completer<void>? signInGate;

  @override
  Stream<IntakeAccount?> accountChanges() async* {
    yield _account;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add((email: email, password: password));
    await signInGate?.future;
    final error = signInError;
    if (error != null) throw error;
    _set(IntakeAccount(id: 'user-${email.split('@').first}', email: email));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _set(null);
  }

  void _set(IntakeAccount? account) {
    _account = account;
    _changes.add(account);
  }
}
