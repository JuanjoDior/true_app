import 'package:flutter/material.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_button.dart';

/// Estado vacío, error o no encontrado. Tono según screens.md §9: gris =
/// vacío, ámbar = error de lectura, azul = no encontrado.
class DsStateMessage extends StatelessWidget {
  const DsStateMessage({
    super.key,
    required this.icon,
    required this.tone,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.announce = false,
  }) : assert(title != null || message != null);

  const DsStateMessage.empty({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : tone = DsColors.textFaint,
       announce = false,
       assert(title != null || message != null);

  const DsStateMessage.error({
    super.key,
    this.icon = Icons.warning_amber_rounded,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : tone = DsStatusColors.inProgress,
       announce = true,
       assert(title != null || message != null);

  const DsStateMessage.notFound({
    super.key,
    this.icon = Icons.search_off_rounded,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : tone = DsStatusColors.open,
       announce = false,
       assert(title != null || message != null);

  final IconData icon;
  final Color tone;
  final String? title;
  final String? message;

  /// El botón solo se muestra con etiqueta y callback a la vez.
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  /// Anuncia el estado a los lectores de pantalla al aparecer (errores).
  final bool announce;

  static const Key iconTileKey = ValueKey('ds-state-message-icon-tile');
  static const double iconTileSize = 60;
  static const double maxWidth = 420;
  static const double _tileAlpha = 0.14;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final title = this.title;
    final message = this.message;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;
    final afterIcon = compact ? DsSpacing.s16 : DsSpacing.s20;
    final afterTitle = compact ? DsSpacing.s8 : DsSpacing.s12;
    final beforeAction = compact ? DsSpacing.s16 : DsSpacing.s24;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            key: iconTileKey,
            width: iconTileSize,
            height: iconTileSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tone.withValues(alpha: _tileAlpha),
                borderRadius: DsRadii.iconBorder,
              ),
              child: Icon(icon, size: 28, color: tone),
            ),
          ),
        ),
        if (title != null) ...[
          SizedBox(height: afterIcon),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact ? styles.displayPoster : styles.displaySection,
          ),
        ],
        if (message != null) ...[
          SizedBox(height: title == null ? afterIcon : afterTitle),
          Text(
            message,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: DsColors.textMuted),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: beforeAction),
          DsButton(
            label: actionLabel,
            variant: DsButtonVariant.glass,
            onPressed: onAction,
          ),
        ],
      ],
    );

    // heightFactor 1: ocupa el ancho y centra, pero la altura es la del contenido
    final body = Align(
      heightFactor: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DsSpacing.s24,
          vertical: compact ? DsSpacing.s16 : DsSpacing.s48,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: column,
        ),
      ),
    );

    if (!announce) return body;
    return Semantics(liveRegion: true, container: true, child: body);
  }
}
