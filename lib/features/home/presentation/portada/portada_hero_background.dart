import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import 'portada_hero_keys.dart';
import 'portada_hero_layout.dart';

// Centro del degradado del prototipo; no existe como token (bgGlow es otro tono).
const Color _glowCenter = Color(0xFF0B1220);
const Color _starColor = Color(0xFFC9D6EA);

// El foco cae sobre el globo (1010, 520) del lienzo de 1440 × 900.
const Alignment _glowAlignment = Alignment(
  1010 / 1440 * 2 - 1,
  520 / 900 * 2 - 1,
);

/// Degradado radial de la portada con las estrellas encima.
class PortadaBackground extends StatelessWidget {
  const PortadaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _glowAlignment,
              radius: 1,
              colors: [_glowCenter, DsColors.bgBase],
            ),
          ),
        ),
        PortadaStarField(key: PortadaHeroKeys.stars),
      ],
    );
  }
}

/// Velo lateral que mantiene legible el texto sobre el globo.
class PortadaVeil extends StatelessWidget {
  const PortadaVeil({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: PortadaLayout.veilWidth,
      child: IgnorePointer(
        child: DecoratedBox(
          key: PortadaHeroKeys.veil,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DsColors.bgBase.withValues(alpha: 0.95),
                DsColors.bgBase.withValues(alpha: 0.7),
                DsColors.bgBase.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una estrella en coordenadas relativas al lienzo (0..1).
class PortadaStar {
  const PortadaStar({
    required this.x,
    required this.y,
    required this.diameter,
    required this.cycles,
    required this.delay,
  });

  final double x;
  final double y;
  final double diameter;

  /// Parpadeos completos por vuelta del reloj de las estrellas.
  final int cycles;

  /// Desfase del parpadeo como fracción de la vuelta.
  final double delay;
}

/// Las 70 estrellas fijas con un único reloj de parpadeo.
class PortadaStarField extends StatefulWidget {
  const PortadaStarField({super.key});

  /// Vuelta completa del reloj; cada estrella parpadea un número entero de veces por vuelta.
  static const Duration cycle = Duration(seconds: 60);
  static const int count = 70;

  static final List<PortadaStar> stars = List.unmodifiable(_generate());

  // Misma distribución que el prototipo; periodos ≈ 2,5 / 3,5 / 4,5 / 5,5 s dentro de una vuelta de 60 s.
  static List<PortadaStar> _generate() {
    const cyclesByGroup = [24, 17, 13, 11];
    return [
      for (var i = 0; i < count; i++)
        PortadaStar(
          x: (i * 997 % 1440) / 1440,
          y: (i * 571 % 900) / 900,
          diameter: i % 3 == 0 ? 2 : 1,
          cycles: cyclesByGroup[i % 4],
          delay: (i % 7) * 0.5 / cycle.inSeconds,
        ),
    ];
  }

  @override
  State<PortadaStarField> createState() => _PortadaStarFieldState();
}

class _PortadaStarFieldState extends State<PortadaStarField>
    with TickerProviderStateMixin {
  AnimationController? _twinkle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _twinkle?.dispose();
      _twinkle = null;
    } else {
      _twinkle ??= AnimationController(
        vsync: this,
        duration: PortadaStarField.cycle,
      )..repeat();
    }
  }

  @override
  void dispose() {
    _twinkle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: PortadaStarsPainter(
            stars: PortadaStarField.stars,
            twinkle: _twinkle,
          ),
        ),
      ),
    );
  }
}

/// Dibuja todas las estrellas de una vez; sin [twinkle] quedan quietas.
class PortadaStarsPainter extends CustomPainter {
  PortadaStarsPainter({required this.stars, this.twinkle})
    : super(repaint: twinkle);

  static const double minOpacity = 0.2;
  static const double maxOpacity = 1;
  static const double staticOpacity = 0.6;

  final List<PortadaStar> stars;
  final Animation<double>? twinkle;

  @override
  void paint(Canvas canvas, Size size) {
    final time = twinkle?.value;
    for (final star in stars) {
      final opacity = time == null ? staticOpacity : _opacityAt(star, time);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.diameter / 2,
        Paint()..color = _starColor.withValues(alpha: opacity),
      );
    }
  }

  // Onda suave entre el mínimo y el máximo, como el ease-in-out del prototipo.
  static double _opacityAt(PortadaStar star, double time) {
    final phase = (star.cycles * (time - star.delay)) % 1;
    final wave = 0.5 - 0.5 * math.cos(2 * math.pi * phase);
    return minOpacity + (maxOpacity - minOpacity) * wave;
  }

  @override
  bool shouldRepaint(PortadaStarsPainter oldDelegate) =>
      oldDelegate.stars != stars || oldDelegate.twinkle != twinkle;
}
