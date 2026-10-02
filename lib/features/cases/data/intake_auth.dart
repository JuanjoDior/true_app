import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_project.dart';

/// Lo que se espera a Supabase al entrar antes de darlo por perdido, igual
/// que al leer el catálogo.
const kIntakeSignInTimeout = Duration(seconds: 15);

/// Cuenta con la que se ha entrado al formulario de alta.
class IntakeAccount {
  const IntakeAccount({required this.id, required this.email});

  final String id;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is IntakeAccount && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// Sesión del formulario de alta.
///
/// Las cuentas se crean a mano desde el panel de Supabase, con contraseña y
/// ya confirmadas: el correo gratuito de Supabase sólo llega a los miembros
/// del equipo del proyecto, así que no hay invitaciones ni enlaces mágicos.
abstract interface class IntakeAuth {
  /// La cuenta actual (o `null`) y después cada cambio de sesión.
  Stream<IntakeAccount?> accountChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Token de acceso sólo si la sesión actual pertenece a [accountId].
  Future<String?> accessTokenForAccount(String accountId);
}

/// [IntakeAuth] contra Supabase Auth.
///
/// Supabase se arranca la primera vez que alguien abre el formulario, no al
/// cargar la web: los visitantes no lo necesitan. La sesión queda guardada en
/// el navegador y la librería renueva el token sola.
class SupabaseIntakeAuth implements IntakeAuth {
  Future<GoTrueClient>? _client;

  Future<GoTrueClient> _auth() => _client ??= _initialize();

  Future<GoTrueClient> _initialize() async {
    try {
      final supabase = await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
        // Se entra con contraseña, nunca volviendo de un enlace: que la
        // librería no interprete las rutas `/#/` de la web como uno.
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      return supabase.client.auth;
    } catch (_) {
      // Que «Reintentar» vuelva a intentarlo de verdad.
      _client = null;
      rethrow;
    }
  }

  @override
  Stream<IntakeAccount?> accountChanges() async* {
    final auth = await _auth();
    yield _toAccount(auth.currentUser);
    yield* auth.onAuthStateChange
        .map((state) => _toAccount(state.session?.user))
        // Un fallo al renovar el token sin conexión llega aquí como error,
        // pero la sesión sigue: si de verdad caduca, llega un cierre de
        // sesión. Sin esto, un corte de red taparía el formulario.
        .handleError((Object _) {});
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final auth = await _auth();
    await auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    final auth = await _auth();
    try {
      await auth.signOut();
    } catch (_) {
      // La librería borra la sesión del navegador antes de avisar al
      // servidor. Si sólo falla ese aviso (sin conexión), aquí ya se ha
      // salido y el token caduca solo.
      if (auth.currentSession != null) rethrow;
    }
  }

  @override
  Future<String?> accessTokenForAccount(String accountId) async {
    final session = (await _auth()).currentSession;
    if (session?.user.id != accountId) return null;
    return session?.accessToken;
  }

  static IntakeAccount? _toAccount(User? user) =>
      user == null ? null : IntakeAccount(id: user.id, email: user.email ?? '');
}

/// Mensaje para quien intenta entrar. Nunca enseña el error en crudo.
String describeSignInError(Object error) {
  if (error is AuthRetryableFetchException ||
      error is ClientException ||
      error is TimeoutException) {
    return 'No se pudo conectar. Revisa la conexión y vuelve a probar.';
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'El email o la contraseña no son correctos.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Demasiados intentos seguidos. Espera unos minutos y vuelve a probar.';
      case 'user_banned':
        return 'Esta cuenta está desactivada. Habla con quien revisa los casos.';
    }
  }
  return 'No se pudo entrar. Vuelve a probar en un momento.';
}
