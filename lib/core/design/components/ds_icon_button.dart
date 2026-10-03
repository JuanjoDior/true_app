import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'ds_pressable.dart';

class DsIconButton extends StatelessWidget {
  const DsIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  static const double size = 44;
  static const Color _transparent = Color(0x00000000);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = onPressed != null;

    return Tooltip(
      message: semanticLabel,
      excludeFromSemantics: true,
      child: DsPressable(
        onTap: onPressed,
        semanticLabel: semanticLabel,
        minTapTarget: const Size.square(size),
        focusRadius: DsRadii.control,
        builder: (context, state) => AnimatedContainer(
          duration: DsMotion.resolve(
            DsMotion.hover,
            reduceMotion: reduceMotion,
          ),
          curve: DsMotion.easeUi,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state.hovered ? DsColors.lineHairline : _transparent,
            borderRadius: DsRadii.controlBorder,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? DsColors.textPrimary : DsColors.textPlaceholder,
          ),
        ),
      ),
    );
  }
}
