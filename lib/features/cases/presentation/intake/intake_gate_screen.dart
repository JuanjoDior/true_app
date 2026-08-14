import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/cases_providers.dart';

/// Clave compartida para desbloquear el workspace de intake de Iván.
///
/// Es un filtro de acceso editorial, no un mecanismo de seguridad real
/// (diseño #7). Constante en código: sin `--dart-define`, sin cambios en CI.
const String kIntakeSharedKey = 'archivo-ivan-2026';

/// Pantalla de acceso al formulario de alta de casos: pide la clave
/// compartida y desbloquea [intakeUnlockedProvider] si coincide.
class IntakeGateScreen extends ConsumerStatefulWidget {
  const IntakeGateScreen({super.key});

  @override
  ConsumerState<IntakeGateScreen> createState() => _IntakeGateScreenState();
}

class _IntakeGateScreenState extends ConsumerState<IntakeGateScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == kIntakeSharedKey) {
      ref.read(intakeUnlockedProvider.notifier).state = true;
      setState(() => _error = null);
    } else {
      setState(() => _error = 'Clave incorrecta. Inténtalo de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  'Introduce la clave compartida para continuar.',
                  style: SituationStyles.sans(
                    size: 13,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('intake-gate-key-field'),
                  controller: _controller,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  style: SituationStyles.sans(
                    size: 14,
                    color: AppColors.textBody,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Clave compartida',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    key: const Key('intake-gate-error'),
                    style: SituationStyles.sans(
                      size: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('intake-gate-submit'),
                  onPressed: _submit,
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
