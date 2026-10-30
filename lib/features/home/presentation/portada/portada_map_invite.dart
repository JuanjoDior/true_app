import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';
import 'portada_closing_keys.dart';
import 'portada_closing_layout.dart';

/// Invitación al mapa: mapa de puntos decorativo con pulsos y un único botón.
class PortadaMapInvite extends StatefulWidget {
  const PortadaMapInvite({super.key, required this.cases, this.onOpenMap});

  final List<TrueCrimeCase> cases;

  /// Nulo oculta el botón; el mapa decorativo y los textos se quedan.
  final VoidCallback? onOpenMap;

  @override
  State<PortadaMapInvite> createState() => _PortadaMapInviteState();
}

class _PortadaMapInviteState extends State<PortadaMapInvite> {
  late List<DsMapMarker> _markers = _toMarkers();

  List<DsMapMarker> _toMarkers() => [
    for (final crimeCase in widget.cases) crimeCase.toMapMarker(),
  ];

  @override
  void didUpdateWidget(PortadaMapInvite oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La escena reindexa los marcadores solo al cambiar la lista: no la recreamos en cada build.
    if (!identical(oldWidget.cases, widget.cases)) _markers = _toMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = PortadaMapInviteMetrics.of(context);
    final stage = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: PortadaMapInviteMetrics.backdropCenter,
              radius: metrics.backdropRadius,
              colors: const [DsColors.bgGlow, DsColors.bgBase],
              stops: [0, metrics.backdropStop],
            ),
          ),
        ),
        // Decoración pura: ni recibe puntero ni aparece en la semántica.
        ExcludeSemantics(
          child: IgnorePointer(
            key: PortadaClosingKeys.mapLayer,
            child: DsMapScene(
              markers: _markers,
              camera: const DsMapCamera.world(),
              mobile: metrics.mobile,
            ),
          ),
        ),
        IgnorePointer(child: _Scrims(mobile: metrics.mobile)),
        _Content(metrics: metrics, onOpenMap: widget.onOpenMap),
      ],
    );

    if (!metrics.mobile) {
      return SizedBox(
        key: PortadaClosingKeys.mapInvite,
        height: metrics.height,
        child: ClipRect(child: stage),
      );
    }
    return Padding(
      key: PortadaClosingKeys.mapInvite,
      padding: metrics.outerPadding,
      child: Container(
        key: PortadaClosingKeys.mapInviteCard,
        height: metrics.height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(PortadaMapInviteMetrics.cardRadius),
          ),
          border: Border.fromBorderSide(
            BorderSide(color: DsColors.lineHairline),
          ),
        ),
        child: stage,
      ),
    );
  }
}

class _Scrims extends StatelessWidget {
  const _Scrims({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    Color base(double alpha) => DsColors.bgBase.withValues(alpha: alpha);
    final List<Gradient> gradients = mobile
        ? [
            LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                base(PortadaMapInviteMetrics.mobileScrimStrong),
                base(PortadaMapInviteMetrics.mobileScrimMid),
                base(0),
              ],
              stops: const [0, PortadaMapInviteMetrics.mobileScrimMidStop, 1],
            ),
          ]
        : [
            LinearGradient(
              colors: [
                base(PortadaMapInviteMetrics.desktopScrimStrong),
                base(PortadaMapInviteMetrics.desktopScrimMid),
                base(0),
              ],
              stops: const [
                0,
                PortadaMapInviteMetrics.desktopScrimMidStop,
                PortadaMapInviteMetrics.desktopScrimEndStop,
              ],
            ),
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [base(1), base(0), base(0), base(1)],
              stops: const [
                0,
                PortadaMapInviteMetrics.desktopEdgeFadeStop,
                1 - PortadaMapInviteMetrics.desktopEdgeFadeStop,
                1,
              ],
            ),
          ];
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final gradient in gradients)
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.metrics, required this.onOpenMap});

  final PortadaMapInviteMetrics metrics;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: metrics.contentGap,
      children: [
        DsMonoLabel(
          'El mapa',
          color: DsColors.accentRed,
          letterSpacingEm: metrics.kickerLetterSpacingEm,
        ),
        Semantics(
          header: true,
          child: Text(
            'El archivo, punto por punto',
            style: styles.displayPage.copyWith(
              fontSize: metrics.titleFontSize,
              height: metrics.titleLineHeight,
              color: DsColors.textStrong,
            ),
          ),
        ),
        if (!metrics.mobile)
          Text(
            'Cada caso tiene su lugar. Acércate, sigue las conexiones entre '
            'casos y recorre décadas con la línea de tiempo.',
            style: styles.bodyLarge.copyWith(
              fontSize: PortadaMapInviteMetrics.bodyFontSize,
              height: PortadaMapInviteMetrics.bodyLineHeight,
              color: DsColors.textBody,
            ),
          ),
        if (onOpenMap != null)
          DsButton(
            label: 'Abrir el mapa',
            onPressed: onOpenMap,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
      ],
    );

    // Con texto muy grande el bloque se reduce en vez de salirse de la sección
    // y dejar el botón fuera del alcance.
    Widget fitted(Alignment alignment) => LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: SizedBox(width: constraints.maxWidth, child: column),
      ),
    );

    if (metrics.mobile) {
      return Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.all(
            PortadaMapInviteMetrics.mobileContentInset,
          ),
          child: fitted(Alignment.bottomLeft),
        ),
      );
    }
    return Positioned(
      left: PortadaMapInviteMetrics.desktopContentLeft,
      top: PortadaMapInviteMetrics.desktopContentTop,
      width: PortadaMapInviteMetrics.desktopContentWidth,
      bottom: 0,
      child: fitted(Alignment.topLeft),
    );
  }
}
