import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

class DsPressableState {
  const DsPressableState({required this.enabled, required this.hovered});

  final bool enabled;
  final bool hovered;
}

/// Interacción común de los controles del sistema: foco de teclado, hover solo
/// de ratón, escala al pulsar y zona táctil mínima. Uso interno de la capa.
class DsPressable extends StatefulWidget {
  const DsPressable({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    required this.builder,
    this.hoverScale = 1,
    this.hoverShiftX = 0,
    this.minTapTarget = Size.zero,
    this.focusRadius = DsRadii.control,
    this.focusNode,
    this.selected,
    this.inMutuallyExclusiveGroup = false,
  });

  static const double pressScale = 0.97;
  static const double focusRingWidth = 2;
  static const double focusRingOffset = 2;
  static const double _ringInset = focusRingOffset + focusRingWidth;
  static const Key focusRingKey = ValueKey('ds-focus-ring');

  static const _activators = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  /// Null deshabilita el control.
  final VoidCallback? onTap;
  final String semanticLabel;
  final Widget Function(BuildContext context, DsPressableState state) builder;
  final double hoverScale;
  final double hoverShiftX;
  final Size minTapTarget;
  final double focusRadius;
  final FocusNode? focusNode;
  final bool? selected;
  final bool inMutuallyExclusiveGroup;

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DsPressableState extends State<DsPressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _focusVisible = false;

  bool get _enabled => widget.onTap != null;

  @override
  void didUpdateWidget(DsPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _hovered = false;
      _pressed = false;
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hovered = _enabled && _hovered;
    final pressed = _enabled && _pressed;

    // Con movimiento reducido solo cambian los colores, nada se desplaza ni escala
    final scale = reduceMotion
        ? 1.0
        : pressed
        ? DsPressable.pressScale
        : hovered
        ? widget.hoverScale
        : 1.0;
    final shiftX = reduceMotion || !hovered ? 0.0 : widget.hoverShiftX;

    Widget visual = Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        widget.builder(
          context,
          DsPressableState(enabled: _enabled, hovered: hovered),
        ),
        if (_focusVisible && _enabled)
          Positioned.fill(
            left: -DsPressable._ringInset,
            top: -DsPressable._ringInset,
            right: -DsPressable._ringInset,
            bottom: -DsPressable._ringInset,
            child: IgnorePointer(
              child: DecoratedBox(
                key: DsPressable.focusRingKey,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    widget.focusRadius + DsPressable._ringInset,
                  ),
                  border: Border.all(
                    color: DsColors.accentRedText,
                    width: DsPressable.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    final duration = DsMotion.resolve(
      pressed ? DsMotion.press : DsMotion.hover,
      reduceMotion: reduceMotion,
    );

    if (widget.hoverShiftX != 0) {
      visual = TweenAnimationBuilder<double>(
        tween: Tween<double>(end: shiftX),
        duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
        curve: DsMotion.easeUi,
        builder: (context, x, child) =>
            Transform.translate(offset: Offset(x, 0), child: child),
        child: visual,
      );
    }

    visual = AnimatedScale(
      scale: scale,
      duration: duration,
      curve: DsMotion.easeUi,
      child: visual,
    );

    if (widget.minTapTarget != Size.zero) {
      visual = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minTapTarget.width,
          minHeight: widget.minTapTarget.height,
        ),
        child: Align(widthFactor: 1, heightFactor: 1, child: visual),
      );
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      focusable: _enabled,
      focused: _focused,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        shortcuts: DsPressable._activators,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        onFocusChange: (value) => setState(() => _focused = value),
        // Solo es true con el modo de resaltado de teclado (no con puntero)
        onShowFocusHighlight: (value) => setState(() => _focusVisible = value),
        child: MouseRegion(
          cursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (event) {
            if (event.kind == PointerDeviceKind.mouse) {
              setState(() => _hovered = true);
            }
          },
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: _enabled ? (_) => _setPressed(true) : null,
            onTapUp: _enabled ? (_) => _setPressed(false) : null,
            onTapCancel: _enabled ? () => _setPressed(false) : null,
            child: visual,
          ),
        ),
      ),
    );
  }
}
