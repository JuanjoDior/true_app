import 'package:flutter/widgets.dart';

import '../tokens/ds_motion.dart';
import 'ds_globe_camera.dart';
import 'ds_globe_math.dart';
import 'ds_globe_style.dart';

const Color _noHalo = Color(0x00000000);
const int _maxChannel = 0xFF;

/// Interpola el halo conservando el tono cuando uno de los extremos es transparente.
class DsGlobeHaloTween extends Tween<Color> {
  DsGlobeHaloTween({super.begin, super.end});

  @override
  Color lerp(double t) {
    final a = begin!;
    final b = end!;
    final from = a.a == 0 ? b : a;
    final to = b.a == 0 ? a : b;
    return Color.lerp(from, to, t)!.withValues(alpha: a.a * (1 - t) + b.a * t);
  }
}

/// Halo de categoría: cambia de color con un fundido (doc 3.4); `null` lo apaga.
class DsGlobeHalo extends StatelessWidget {
  const DsGlobeHalo({super.key, required this.camera, required this.color});

  final DsGlobeCamera camera;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color>(
      tween: DsGlobeHaloTween(end: color ?? _noHalo),
      duration: DsMotion.resolve(
        DsGlobeStyle.haloFade,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
      ),
      builder: (context, value, _) => CustomPaint(
        painter: DsGlobeHaloPainter(camera: camera, color: value),
      ),
    );
  }
}

class DsGlobeHaloPainter extends CustomPainter {
  const DsGlobeHaloPainter({required this.camera, required this.color});

  final DsGlobeCamera camera;
  final Color color;

  static RadialGradient gradient(Color color) {
    final tint = color.withValues(
      alpha: color.a * DsGlobeStyle.haloAlpha / _maxChannel,
    );
    return RadialGradient(
      colors: [tint, tint.withValues(alpha: 0)],
      stops: const [0, DsGlobeStyle.haloTransparentStop],
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a <= 0) return;
    final radius = DsGlobeStyle.haloDiameter / 2 * camera.scale;
    final rect = Rect.fromCircle(center: camera.center, radius: radius);
    canvas.drawCircle(
      camera.center,
      radius,
      Paint()..shader = gradient(color).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(DsGlobeHaloPainter oldDelegate) =>
      oldDelegate.camera != camera || oldDelegate.color != color;
}

/// Cuerpo de la esfera: resplandor exterior, disco con degradado y borde.
class DsGlobeBodyPainter extends CustomPainter {
  const DsGlobeBodyPainter({required this.camera});

  final DsGlobeCamera camera;

  static final RadialGradient bodyGradient = RadialGradient(
    center: DsGlobeStyle.alignmentOf(
      DsGlobeStyle.bodyFocalX,
      DsGlobeStyle.bodyFocalY,
    ),
    radius: DsGlobeStyle.bodyGradientRadius,
    colors: const [
      DsGlobeStyle.bodyCore,
      DsGlobeStyle.bodyMid,
      DsGlobeStyle.bodyEdge,
    ],
    stops: const [0, DsGlobeStyle.bodyMidStop, 1],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = camera.center;
    final radius = DsGlobeMath.radius * camera.scale;
    final disc = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = DsGlobeStyle.outerGlowColor
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          DsGlobeStyle.outerGlowBlur *
              DsGlobeStyle.blurSigmaPerBlur *
              camera.scale,
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = bodyGradient.createShader(disc),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = DsGlobeStyle.borderWidth
        ..color = DsGlobeStyle.borderColor,
    );
  }

  @override
  bool shouldRepaint(DsGlobeBodyPainter oldDelegate) =>
      oldDelegate.camera != camera;
}

/// Sombreado sobre la tierra: brillo especular y oscurecimiento del borde.
class DsGlobeShadingPainter extends CustomPainter {
  const DsGlobeShadingPainter({required this.camera});

  final DsGlobeCamera camera;

  static final RadialGradient highlightGradient = RadialGradient(
    center: DsGlobeStyle.alignmentOf(
      DsGlobeStyle.highlightFocalX,
      DsGlobeStyle.highlightFocalY,
    ),
    radius: DsGlobeStyle.highlightRadius,
    colors: [
      DsGlobeStyle.highlightColor,
      DsGlobeStyle.highlightColor.withValues(alpha: 0),
    ],
  );

  static final RadialGradient limbGradient = RadialGradient(
    radius: DsGlobeStyle.bodyGradientRadius,
    colors: [
      DsGlobeStyle.limbColor.withValues(alpha: 0),
      DsGlobeStyle.limbColor,
    ],
    stops: const [DsGlobeStyle.limbClearStop, 1],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final radius = DsGlobeMath.radius * camera.scale;
    final disc = Rect.fromCircle(center: camera.center, radius: radius);
    for (final gradient in [highlightGradient, limbGradient]) {
      canvas.drawCircle(
        camera.center,
        radius,
        Paint()..shader = gradient.createShader(disc),
      );
    }
  }

  @override
  bool shouldRepaint(DsGlobeShadingPainter oldDelegate) =>
      oldDelegate.camera != camera;
}
