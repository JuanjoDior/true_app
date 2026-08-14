import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/navigation/app_navigation_scope.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/presentation/case_directory.dart';

/// Rail lateral de iconos de la Sala de Situación.
///
/// El primer ítem (mapa/radar) es la vista activa por defecto; el ítem de
/// "añadir caso" abre el workspace de intake de Iván.
class SituationNavRail extends ConsumerWidget {
  const SituationNavRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);

    return Container(
      width: 64,
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(right: BorderSide(color: AppColors.panelMuted)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _RailItem(
            icon: Icons.radar_rounded,
            active: workspace == Workspace.situationRoom,
          ),
          const SizedBox(height: 6),
          // Llevaba aquí sin `onTap` desde el principio, esperando a tener un
          // archivo que listar. Ya lo tiene.
          _RailItem(
            key: const Key('rail-case-directory'),
            icon: Icons.format_list_bulleted_rounded,
            onTap: () {
              final navigation = AppNavigationScope.maybeOf(context);
              if (navigation != null) {
                showCaseDirectory(context, navigation);
              }
            },
          ),
          const SizedBox(height: 6),
          const _RailItem(icon: Icons.hub_outlined),
          const SizedBox(height: 6),
          const _RailItem(icon: Icons.bookmark_border_rounded),
          const SizedBox(height: 6),
          _RailItem(
            key: const Key('nav-rail-intake-entry'),
            icon: Icons.add_box_outlined,
            active: workspace == Workspace.intake,
            onTap: () =>
                ref.read(workspaceProvider.notifier).state = Workspace.intake,
          ),
          const Spacer(),
          const _RailAvatar(),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: active ? const Color(0xFFE5605A) : AppColors.textFaint,
          ),
        ),
      ),
    );
  }
}

class _RailAvatar extends StatelessWidget {
  const _RailAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1D24), Color(0xFF171922)],
        ),
      ),
    );
  }
}
