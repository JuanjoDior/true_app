import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/ds_colors.dart';

class DsMonoLabel extends StatelessWidget {
  const DsMonoLabel(
    this.text, {
    super.key,
    this.color,
    this.letterSpacingEm = 0.18,
  }) : assert(
         letterSpacingEm >= 0.14 && letterSpacingEm <= 0.24,
         'DESIGN.md 3.2: el interletrado mono va de 0,14 a 0,24 em',
       );

  final String text;
  final Color? color;
  final double letterSpacingEm;

  @override
  Widget build(BuildContext context) {
    final base = DsTextStylesResolver.of(context).monoLabel;
    final style = base.copyWith(
      color: color ?? DsColors.textMuted,
      letterSpacing: letterSpacingEm * base.fontSize!,
    );

    // El lector de pantalla recibe el texto original, no las mayúsculas
    return Semantics(
      label: text,
      child: ExcludeSemantics(child: Text(text.toUpperCase(), style: style)),
    );
  }
}
