import 'dart:async';

import 'package:true_app/features/cases/data/intake_auth.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

const kTestAccount = IntakeAccount(id: 'user-ivan', email: 'ivan@example.com');

/// Borrador con todos los campos obligatorios: pasa la validación de envío.
CaseDraft submittableTestDraft({
  String draftId = 'draft-envio',
  String title = 'Título confidencial del caso',
}) => CaseDraft(
  draftId: draftId,
  title: title,
  category: CaseCategory.unsolved,
  year: 2001,
  status: CaseStatus.open,
  country: 'España',
  countryCode: 'ES',
  regionOrCity: 'Cuenca',
  latitude: 40.07,
  longitude: -2.13,
);

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

  /// Si se fija, `signOut` falla con esto y la sesión sigue abierta.
  Object? signOutError;

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
    final error = signOutError;
    if (error != null) throw error;
    _set(null);
  }

  @override
  Future<String?> accessTokenForAccount(String accountId) async =>
      _account?.id == accountId ? 'token-$accountId' : null;

  void _set(IntakeAccount? account) {
    _account = account;
    _changes.add(account);
  }
}
