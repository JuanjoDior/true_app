import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../application/intake_session_providers.dart';
import 'intake_sign_in_screen.dart';

/// Con quién se ha entrado, y la salida. Va al pie de la lista y no en la
/// barra superior, que en pantallas estrechas ya no tiene sitio.
class IntakeAccountFooter extends ConsumerWidget {
  const IntakeAccountFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(intakeAccountProvider).value;
    final styles = DsTextStylesResolver.of(context);
    return Container(
      padding: const EdgeInsets.all(DsSpacing.s16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DsColors.lineHairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (account == null)
            const Align(
              alignment: Alignment.centerLeft,
              child: DsMonoLabel('Sin sesión'),
            )
          else
            // Texto llano: un correo en mayúsculas dejaría de ser el correo
            Text(
              account.email,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: styles.body.copyWith(
                fontSize: 13,
                color: DsColors.textMuted,
              ),
            ),
          const SizedBox(height: DsSpacing.s8),
          Text(
            'Borradores guardados en este dispositivo',
            key: const Key('intake-local-drafts-status'),
            style: styles.body.copyWith(
              fontSize: 13,
              height: 1.5,
              color: DsColors.textMuted,
            ),
          ),
          const SizedBox(height: DsSpacing.s12),
          if (account == null)
            DsButton(
              key: const Key('intake-signin-open'),
              label: 'Iniciar sesión',
              variant: DsButtonVariant.glass,
              expand: true,
              onPressed: () => _showSignIn(context),
            )
          else
            DsButton(
              key: const Key('intake-signout-button'),
              label: 'Cerrar sesión',
              variant: DsButtonVariant.glass,
              expand: true,
              onPressed: () => _signOut(context, ref),
            ),
        ],
      ),
    );
  }

  void _showSignIn(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _IntakeSignInDialog(),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(intakeAuthProvider).signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión. Vuelve a probar.'),
        ),
      );
    }
  }
}

class _IntakeSignInDialog extends ConsumerWidget {
  const _IntakeSignInDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(intakeAccountProvider, (previous, next) {
      if (next.value != null && context.mounted) {
        Navigator.of(context).pop();
      }
    });
    return Dialog.fullscreen(
      child: Stack(
        children: [
          const IntakeSignInScreen(),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                key: const Key('intake-signin-close'),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
