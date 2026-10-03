import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_glass_panel.dart';

class DsToast extends StatelessWidget {
  const DsToast({super.key, required this.message});

  final String message;

  static const Duration enterDuration = Duration(milliseconds: 250);
  static const Duration exitDuration = Duration(milliseconds: 150);
  static const double slideDistance = 24;
  static const double desktopInset = DsSpacing.s24;
  static const double mobileSideInset = DsSpacing.s16;
  static const double mobileBottomInset = DsSpacing.s32;
  static const double maxWidthDesktop = 420;
  static const double _iconDiscSize = 26;
  static const double _borderAlpha = 0.5;
  static const double _discAlpha = 0.16;

  static _ActiveToast? _active;

  /// Muestra el aviso y sustituye al anterior si seguía visible.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _active?.remove();

    final active = _ActiveToast();
    active.entry = OverlayEntry(
      builder: (context) => _DsToastFrame(
        message: message,
        duration: duration,
        onDismissed: active.remove,
        onDisposed: () {
          if (identical(_active, active)) _active = null;
        },
      ),
    );
    _active = active;
    overlay.insert(active.entry);
  }

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);

    return Semantics(
      liveRegion: true,
      container: true,
      child: DsGlassPanel(
        strong: true,
        borderRadius: DsRadii.controlBorder,
        borderColor: DsStatusColors.solved.withValues(alpha: _borderAlpha),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.s18,
          vertical: DsSpacing.s14,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: _iconDiscSize,
                height: _iconDiscSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DsStatusColors.solved.withValues(alpha: _discAlpha),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: DsStatusColors.solved,
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.s14),
            Flexible(
              child: Text(
                message,
                style: styles.body.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  color: DsColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveToast {
  late final OverlayEntry entry;
  bool _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    entry.remove();
    entry.dispose();
  }
}

class _DsToastFrame extends StatefulWidget {
  const _DsToastFrame({
    required this.message,
    required this.duration,
    required this.onDismissed,
    required this.onDisposed,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismissed;
  final VoidCallback onDisposed;

  @override
  State<_DsToastFrame> createState() => _DsToastFrameState();
}

class _DsToastFrameState extends State<_DsToastFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _eased = _controller.drive(
    CurveTween(curve: DsMotion.easeUi),
  );
  late final Timer _timer;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller
      ..duration = DsMotion.resolve(
        DsToast.enterDuration,
        reduceMotion: reduceMotion,
      )
      ..reverseDuration = DsMotion.resolve(
        DsToast.exitDuration,
        reduceMotion: reduceMotion,
      );
    if (!_entered) {
      _entered = true;
      _controller.forward();
    }
  }

  // Si se destruye a mitad de la salida el futuro nunca completa: no hay doble baja
  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) => widget.onDismissed());
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final isDesktop = size.width >= DsBreakpoints.desktop;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final distance = reduceMotion ? 0.0 : DsToast.slideDistance;
    final from = isDesktop ? Offset(distance, 0) : Offset(0, distance);

    final toast = AnimatedBuilder(
      animation: _eased,
      builder: (context, child) =>
          Transform.translate(offset: from * (1 - _eased.value), child: child),
      child: FadeTransition(
        opacity: _eased,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? DsToast.maxWidthDesktop : double.infinity,
          ),
          child: DsToast(message: widget.message),
        ),
      ),
    );

    // Sin Material el texto del overlay saldría subrayado
    return Positioned.fill(
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: isDesktop
                ? EdgeInsets.fromLTRB(
                    0,
                    safe.top + DsToast.desktopInset,
                    safe.right + DsToast.desktopInset,
                    0,
                  )
                : EdgeInsets.fromLTRB(
                    safe.left + DsToast.mobileSideInset,
                    0,
                    safe.right + DsToast.mobileSideInset,
                    safe.bottom + DsToast.mobileBottomInset,
                  ),
            child: Align(
              alignment: isDesktop
                  ? Alignment.topRight
                  : Alignment.bottomCenter,
              child: toast,
            ),
          ),
        ),
      ),
    );
  }
}
