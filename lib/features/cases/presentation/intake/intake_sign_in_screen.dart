import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/intake_session_providers.dart';
import '../../data/intake_auth.dart';

/// Entrada al formulario de alta con email y contraseña.
///
/// No hay registro ni «olvidé mi contraseña»: las cuentas las crea quien
/// revisa los casos desde el panel de Supabase, y es quien la cambia.
class IntakeSignInScreen extends ConsumerStatefulWidget {
  const IntakeSignInScreen({super.key});

  @override
  ConsumerState<IntakeSignInScreen> createState() => _IntakeSignInScreenState();
}

class _IntakeSignInScreenState extends ConsumerState<IntakeSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Escribe tu email y tu contraseña.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(intakeAuthProvider)
          .signIn(email: email, password: password);
      // Al entrar, el formulario sustituye a esta pantalla.
    } catch (error) {
      if (mounted) setState(() => _error = describeSignInError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = SituationStyles.sans(
      size: 14,
      color: AppColors.textBody,
    );
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Acceso al formulario de casos',
                    style: SituationStyles.serif(size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra con tu email y tu contraseña.',
                    style: SituationStyles.sans(
                      size: 13,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('intake-signin-email'),
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    style: fieldStyle,
                    decoration: const InputDecoration(hintText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('intake-signin-password'),
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    style: fieldStyle,
                    decoration: const InputDecoration(hintText: 'Contraseña'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      key: const Key('intake-signin-error'),
                      style: SituationStyles.sans(
                        size: 12,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('intake-signin-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Entrando…' : 'Entrar'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¿Sin cuenta o sin contraseña? Pídesela a quien revisa '
                    'los casos.',
                    style: SituationStyles.sans(
                      size: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
