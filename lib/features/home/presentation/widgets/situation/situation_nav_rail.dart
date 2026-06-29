import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Rail lateral de iconos de la Sala de Situación.
///
/// Por ahora es navegación visual: el primer ítem (mapa/radar) queda activo.
class SituationNavRail extends StatelessWidget {
  const SituationNavRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(right: BorderSide(color: AppColors.panelMuted)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: const [
          _RailItem(icon: Icons.radar_rounded, active: true),
          SizedBox(height: 6),
          _RailItem(icon: Icons.format_list_bulleted_rounded),
          SizedBox(height: 6),
          _RailItem(icon: Icons.hub_outlined),
          SizedBox(height: 6),
          _RailItem(icon: Icons.bookmark_border_rounded),
          Spacer(),
          _RailAvatar(),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
