import 'package:flutter/material.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_glass_panel.dart';

class DsDialog extends StatelessWidget {
  const DsDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  static const double maxWidth = 480;
  static const double radius = 20;
  static const double titleFontSize = 22;
  static const Color barrierColor = Color.fromRGBO(0, 0, 0, 0.6);
  static const Duration enterDuration = Duration(milliseconds: 200);
  static const Duration exitDuration = Duration(milliseconds: 150);
  // Nunca desde 0: un modal que nace de la nada se percibe como un salto
  static const double enterScale = 0.96;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    // Material propio: la ruta del diálogo no lo aporta y los campos lo exigen
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: styles.body,
          child: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DsSpacing.s24,
                DsSpacing.s24,
                DsSpacing.s24,
                DsSpacing.s24 + keyboard,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: DsGlassPanel(
                  strong: true,
                  borderRadius: BorderRadius.circular(radius),
                  shadows: DsShadows.modal,
                  padding: const EdgeInsets.all(DsSpacing.s24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título y contenido hacen scroll; las acciones quedan fijas
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                style: styles.displayCard.copyWith(
                                  fontSize: titleFontSize,
                                  color: DsColors.textStrong,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.s16),
                              content,
                            ],
                          ),
                        ),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.s24),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: DsSpacing.s12,
                          runSpacing: DsSpacing.s12,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// showGeneralDialog no permite una salida más corta que la entrada
class _DsDialogRoute<T> extends RawDialogRoute<T> {
  _DsDialogRoute({
    required super.pageBuilder,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.transitionDuration,
    required super.transitionBuilder,
    required this.exitDuration,
  }) : super(barrierColor: DsDialog.barrierColor);

  final Duration exitDuration;

  @override
  Duration get reverseTransitionDuration => exitDuration;
}

Future<T?> showDsDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final barrierLabel = MaterialLocalizations.of(
    context,
  ).modalBarrierDismissLabel;

  return Navigator.of(context, rootNavigator: true).push<T>(
    _DsDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      transitionDuration: DsMotion.resolve(
        DsDialog.enterDuration,
        reduceMotion: reduceMotion,
      ),
      exitDuration: DsMotion.resolve(
        DsDialog.exitDuration,
        reduceMotion: reduceMotion,
      ),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion) {
          return FadeTransition(opacity: animation, child: child);
        }
        final eased = CurveTween(curve: DsMotion.easeUi);
        return FadeTransition(
          opacity: animation.drive(eased),
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: DsDialog.enterScale, end: 1).chain(eased),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    ),
  );
}
