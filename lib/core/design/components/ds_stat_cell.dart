import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_mono_label.dart';

enum DsStatValueStyle { serif, mono }

class DsStatCell extends StatelessWidget {
  const DsStatCell({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle = DsStatValueStyle.mono,
  });

  final String label;
  final String value;
  final DsStatValueStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final style = switch (valueStyle) {
      DsStatValueStyle.mono => styles.monoData,
      DsStatValueStyle.serif => styles.displaySection.copyWith(
        fontSize: 24,
        color: DsColors.textStrong,
      ),
    };

    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsMonoLabel(label),
            const SizedBox(height: DsSpacing.s4),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }
}
