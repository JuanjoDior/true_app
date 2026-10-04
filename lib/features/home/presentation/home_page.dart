import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cases/application/cases_providers.dart';
import '../../cases/presentation/intake/intake_workspace_screen.dart';
import 'portada/portada_shell.dart';

/// Portada de la aplicación. Alterna con el workspace de intake de Iván según
/// `workspaceProvider`.
class TrueCrimeHomePage extends ConsumerWidget {
  const TrueCrimeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    if (workspace == Workspace.intake) {
      return const IntakeWorkspaceScreen();
    }

    return const PortadaShell();
  }
}
