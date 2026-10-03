import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_route_controller.dart';
import 'package:true_app/app/navigation/app_route_path.dart';

/// El estado de ruta y sus movimientos [diseño §7.3].
///
/// La ruta es un único estado, no una pila: cada movimiento sustituye lo que
/// hubiera. Por eso Atrás desde cualquier ruta apilada vuelve a la raíz.

AppRouteController _controller() {
  final controller = AppRouteController();
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('abrir el mapa', () {
    test('opening the map moves to the map path', () {
      final controller = _controller();

      controller.openMap();

      expect(controller.path, const MapPath());
    });

    test('opening the map notifies once', () {
      final controller = _controller();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.openMap();

      expect(notifications, 1);
    });

    test('opening the map twice does not notify again', () {
      final controller = _controller();
      controller.openMap();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.openMap();

      expect(notifications, 0);
    });

    test('opening the map twice keeps the map path', () {
      final controller = _controller();
      controller.openMap();

      controller.openMap();

      expect(controller.path, const MapPath());
    });

    test('opening the map from a case replaces the detail', () {
      // El estado es una sola ruta: el mapa sustituye al detalle, no se apila
      // sobre él, así que Atrás desde el mapa vuelve a la raíz.
      final controller = _controller();
      controller.openCase('isdal');

      controller.openMap();

      expect(controller.path, const MapPath());
    });

    test('opening the map from an unknown path replaces it', () {
      final controller = _controller();
      controller.restore(UnknownAppPath(Uri.parse('/ajustes')));

      controller.openMap();

      expect(controller.path, const MapPath());
    });
  });

  group('salir del mapa', () {
    test('opening a case from the map goes to its detail', () {
      final controller = _controller();
      controller.openMap();

      controller.openCase('isdal');

      expect(controller.path, const CaseDetailPath('isdal'));
    });

    test('showing the Situation Room from the map returns to the root', () {
      final controller = _controller();
      controller.openMap();

      controller.showSituationRoom();

      expect(controller.path, const SituationRoomPath());
    });

    test('showing the Situation Room from the map notifies once', () {
      final controller = _controller();
      controller.openMap();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.showSituationRoom();

      expect(notifications, 1);
    });

    test('restoring the map path from the engine moves to the map', () {
      final controller = _controller();

      controller.restore(const MapPath());

      expect(controller.path, const MapPath());
    });
  });
}
