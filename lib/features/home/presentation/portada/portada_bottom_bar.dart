import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import 'portada_shell_keys.dart';

/// Barra inferior móvil: Inicio · Mapa · Archivo · Formulario.
class PortadaBottomBar extends StatelessWidget {
  const PortadaBottomBar({
    super.key,
    required this.onHome,
    required this.onOpenMap,
    required this.onOpenForm,
    this.onOpenArchive,
  });

  final VoidCallback onHome;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenForm;

  /// Nulo oculta la pestaña: sin navegación no hay directorio al que ir.
  final VoidCallback? onOpenArchive;

  static const double height = 68;

  /// Alto total que ocupa, con el área segura inferior.
  static double heightOf(BuildContext context) =>
      height + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsGlassPanel.blurSigma,
          sigmaY: DsGlassPanel.blurSigma,
        ),
        child: Container(
          key: PortadaShellKeys.bottomBar,
          height: heightOf(context),
          padding: EdgeInsets.fromLTRB(
            DsSpacing.s8,
            0,
            DsSpacing.s8,
            MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: DsColors.surfaceChrome,
            border: Border(top: BorderSide(color: DsColors.lineHairline)),
          ),
          child: Row(
            children: [
              _Tab(
                key: PortadaShellKeys.bottomBarHome,
                label: 'Inicio',
                icon: Icons.home_outlined,
                selected: true,
                onTap: onHome,
              ),
              _Tab(
                key: PortadaShellKeys.bottomBarMap,
                label: 'Mapa',
                icon: Icons.public_rounded,
                onTap: onOpenMap,
              ),
              if (onOpenArchive != null)
                _Tab(
                  key: PortadaShellKeys.bottomBarArchive,
                  label: 'Archivo',
                  icon: Icons.format_list_bulleted_rounded,
                  onTap: onOpenArchive!,
                ),
              _Tab(
                key: PortadaShellKeys.bottomBarForm,
                label: 'Formulario',
                icon: Icons.add_box_outlined,
                onTap: onOpenForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final color = selected ? DsColors.textStrong : DsColors.textMuted;
    return Expanded(
      child: DsPressable(
        onTap: onTap,
        semanticLabel: label,
        selected: selected,
        builder: (context, state) => SizedBox(
          height: PortadaBottomBar.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: DsSpacing.s4,
            children: [
              Icon(icon, size: 22, color: color),
              Text(
                label,
                style: styles.body.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
