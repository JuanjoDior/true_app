import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_carousel_controller.dart';

const _slide = Duration(seconds: 7);
const _justBefore = Duration(milliseconds: 6999);
const _oneMs = Duration(milliseconds: 1);

// El ticker arranca en el primer fotograma: sin él el tiempo previo no cuenta.
Future<PortadaCarouselController> _create(
  WidgetTester tester, {
  int length = 5,
  int initialIndex = 0,
  Duration interval = _slide,
  bool disposeAtEnd = true,
}) async {
  final controller = PortadaCarouselController(
    length: length,
    vsync: tester,
    initialIndex: initialIndex,
    interval: interval,
  );
  if (disposeAtEnd) _created.add(controller);
  await tester.pump();
  return controller;
}

final List<PortadaCarouselController> _created = [];

// Los tickers se verifican al acabar el cuerpo del test, antes de los tearDown.
void _test(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      for (final controller in _created) {
        controller.dispose();
      }
      _created.clear();
    }
  });
}

void main() {
  group('arranque', () {
    _test('empieza en el índice inicial con progreso 0', (tester) async {
      final controller = await _create(tester, initialIndex: 2);

      expect(controller.index, 2);
      expect(controller.length, 5);
      expect(controller.progress.value, 0);
      expect(controller.isPaused, isFalse);
    });

    _test('el intervalo por defecto es el del carrusel de escritorio', (
      tester,
    ) async {
      final controller = PortadaCarouselController(length: 3, vsync: tester);
      _created.add(controller);

      expect(controller.interval, _slide);
    });

    _test('un índice inicial fuera de rango se acota', (tester) async {
      final high = await _create(tester, length: 3, initialIndex: 9);
      final low = await _create(tester, length: 3, initialIndex: -4);

      expect(high.index, 2);
      expect(low.index, 0);
    });
  });

  group('autoavance', () {
    _test('a los 6999 ms sigue en el mismo slide', (tester) async {
      final controller = await _create(tester);

      await tester.pump(_justBefore);

      expect(controller.index, 0);
      expect(controller.progress.value, closeTo(0.9999, 1e-4));
    });

    _test('a los 7000 ms avanza y el progreso vuelve a 0', (
      tester,
    ) async {
      final controller = await _create(tester);

      await tester.pump(_justBefore);
      await tester.pump(_oneMs);

      expect(controller.index, 1);
      expect(controller.progress.value, 0);
    });

    _test('el progreso es lineal en 7 s', (tester) async {
      final controller = await _create(tester);

      await tester.pump(const Duration(milliseconds: 3500));
      expect(controller.progress.value, closeTo(0.5, 1e-9));

      await tester.pump(const Duration(milliseconds: 1750));
      expect(controller.progress.value, closeTo(0.75, 1e-9));
    });

    _test('de forma sostenida cada slide dura 7 s', (tester) async {
      final controller = await _create(tester);

      for (var expected = 1; expected <= 3; expected++) {
        await tester.pump(_slide);
        expect(controller.index, expected);
      }
    });

    _test('tras el último vuelve al primero', (tester) async {
      final controller = await _create(tester, length: 3);

      await tester.pump(_slide);
      await tester.pump(_slide);
      expect(controller.index, 2);

      await tester.pump(_slide);
      expect(controller.index, 0);
    });

    _test('respeta un intervalo propio', (tester) async {
      final controller = await _create(
        tester,
        interval: const Duration(seconds: 2),
      );

      await tester.pump(const Duration(milliseconds: 1999));
      expect(controller.index, 0);

      await tester.pump(_oneMs);
      expect(controller.index, 1);
    });

    _test('notifica una vez por cambio de slide', (tester) async {
      final controller = await _create(tester);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await tester.pump(_slide);
      await tester.pump(_slide);

      expect(notifications, 2);
    });
  });

  group('interacción', () {
    _test('select cambia de slide y reinicia los 7 s', (tester) async {
      final controller = await _create(tester);
      await tester.pump(const Duration(seconds: 5));

      controller.select(3);
      await tester.pump();

      expect(controller.index, 3);
      expect(controller.progress.value, 0);

      await tester.pump(_justBefore);
      expect(controller.index, 3);

      await tester.pump(_oneMs);
      expect(controller.index, 4);
    });

    _test('pulsar el slide activo reinicia el tiempo sin notificar', (
      tester,
    ) async {
      final controller = await _create(tester);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await tester.pump(const Duration(seconds: 6));

      controller.select(0);
      await tester.pump();

      expect(notifications, 0);
      expect(controller.progress.value, 0);

      await tester.pump(_justBefore);
      expect(controller.index, 0);
    });

    _test('select fuera de rango se ignora', (tester) async {
      final controller = await _create(tester, length: 3);
      await tester.pump(const Duration(seconds: 4));
      final before = controller.progress.value;

      controller.select(3);
      controller.select(-1);
      await tester.pump();

      expect(controller.index, 0);
      expect(controller.progress.value, closeTo(before, 1e-9));
    });

    _test('next avanza con vuelta y reinicia', (tester) async {
      final controller = await _create(tester, length: 2, initialIndex: 1);
      await tester.pump(const Duration(seconds: 3));

      controller.next();
      await tester.pump();

      expect(controller.index, 0);
      expect(controller.progress.value, 0);
    });
  });

  group('pausa', () {
    _test('pause congela el avance y el progreso', (tester) async {
      final controller = await _create(tester);
      await tester.pump(const Duration(seconds: 3));

      controller.pause();
      final frozen = controller.progress.value;
      await tester.pump(const Duration(seconds: 30));

      expect(controller.isPaused, isTrue);
      expect(controller.index, 0);
      expect(controller.progress.value, frozen);
      expect(tester.binding.transientCallbackCount, 0);
    });

    _test('resume continúa desde donde quedó', (tester) async {
      final controller = await _create(tester);
      await tester.pump(const Duration(seconds: 3));
      controller.pause();
      await tester.pump(const Duration(seconds: 30));

      controller.resume();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3999));
      expect(controller.index, 0);

      await tester.pump(_oneMs);
      expect(controller.index, 1);
    });

    _test('resume sin pausa previa no reinicia el tiempo', (
      tester,
    ) async {
      final controller = await _create(tester);
      await tester.pump(const Duration(seconds: 3));

      controller.resume();
      await tester.pump(const Duration(seconds: 4));

      expect(controller.index, 1);
    });

    _test('en pausa select cambia de slide pero no arranca el reloj', (
      tester,
    ) async {
      final controller = await _create(tester);
      controller.pause();

      controller.select(2);
      await tester.pump(const Duration(seconds: 30));

      expect(controller.index, 2);
      expect(controller.progress.value, 0);
      expect(tester.binding.transientCallbackCount, 0);
    });

    _test('en pausa next sigue funcionando', (tester) async {
      final controller = await _create(tester);
      controller.pause();

      controller.next();

      expect(controller.index, 1);
    });

    _test('pausar dos veces y reanudar una arranca el reloj', (
      tester,
    ) async {
      final controller = await _create(tester);
      controller.pause();
      controller.pause();

      controller.resume();
      await tester.pump();
      await tester.pump(_slide);

      expect(controller.index, 1);
    });
  });

  group('longitud', () {
    for (final length in [0, 1]) {
      _test('con length $length nunca avanza ni usa ticker', (
        tester,
      ) async {
        final controller = await _create(tester, length: length);

        await tester.pump(const Duration(seconds: 30));

        expect(controller.index, 0);
        expect(controller.progress.value, 0);
        expect(tester.binding.transientCallbackCount, 0);

        controller.next();
        controller.select(0);
        controller.resume();
        await tester.pump(const Duration(seconds: 30));
        expect(controller.index, 0);
        expect(tester.binding.transientCallbackCount, 0);
      });
    }

    _test('al pasar de 1 a 3 slides empieza a avanzar', (tester) async {
      final controller = await _create(tester, length: 1);

      controller.length = 3;
      await tester.pump();
      await tester.pump(_slide);

      expect(controller.length, 3);
      expect(controller.index, 1);
    });

    _test('al reducir la longitud el índice se acota y se notifica', (
      tester,
    ) async {
      final controller = await _create(tester, initialIndex: 4);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.length = 2;

      expect(controller.index, 1);
      expect(notifications, 1);
    });

    _test('al quedar en 1 slide se detiene', (tester) async {
      final controller = await _create(tester);

      controller.length = 1;
      await tester.pump(const Duration(seconds: 30));

      expect(controller.index, 0);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('dispose', () {
    _test('cancela el reloj: no queda ticker ni avanza', (tester) async {
      final controller = await _create(tester, disposeAtEnd: false);
      await tester.pump(const Duration(seconds: 3));

      controller.dispose();
      await tester.pump(const Duration(seconds: 30));

      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
