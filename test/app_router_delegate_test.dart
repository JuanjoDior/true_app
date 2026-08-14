import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_route_controller.dart';
import 'package:true_app/app/navigation/app_route_information_parser.dart';
import 'package:true_app/app/navigation/app_route_path.dart';
import 'package:true_app/app/navigation/app_router_delegate.dart';

/// La pila de páginas y el historial [diseño §7.3].
///
/// El delegate recibe los constructores de página por inyección. No es
/// ceremonia: es lo que le permite existir en esta unidad sin conocer todavía
/// `CaseDetailPage`, que llega en la Unit 7, y sin dejar widgets marcador
/// muertos por el camino.

Widget _marker(String label) => Text(label, textDirection: TextDirection.ltr);

({AppRouteController controller, AppRouterDelegate delegate}) _wire() {
  final controller = AppRouteController();
  final delegate = AppRouterDelegate(
    controller: controller,
    situationRoomBuilder: (context) => _marker('sala'),
    caseDetailBuilder: (context, slug) => _marker('detalle:$slug'),
    routeNotFoundBuilder: (context, uri) => _marker('desconocida:$uri'),
  );
  addTearDown(delegate.dispose);
  addTearDown(controller.dispose);
  return (controller: controller, delegate: delegate);
}

Future<void> _pumpRouter(
  WidgetTester tester,
  AppRouterDelegate delegate,
) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerDelegate: delegate,
      routeInformationParser: AppRouteInformationParser(),
      routeInformationProvider: PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('pila de páginas', () {
    testWidgets('the root route shows only the Situation Room', (tester) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);

      expect(find.text('detalle:isdal'), findsNothing);
    });

    testWidgets('the root route does show the Situation Room', (tester) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);

      expect(find.text('sala'), findsOneWidget);
    });

    testWidgets('a case route puts the detail page on top', (tester) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);

      wired.controller.openCase('isdal');
      await tester.pumpAndSettle();

      expect(find.text('detalle:isdal'), findsOneWidget);
    });

    testWidgets('a case route keeps the Situation Room underneath', (
      tester,
    ) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);

      wired.controller.openCase('isdal');
      await tester.pumpAndSettle();

      // El detalle va ENCIMA de la raíz, no en su lugar. Eso es lo que hace
      // que volver revele lo que ya hubiera debajo.
      expect(find.text('sala', skipOffstage: false), findsOneWidget);
    });

    testWidgets('an unknown route shows the not-found page', (tester) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);

      wired.controller.restore(UnknownAppPath(Uri.parse('/ajustes')));
      await tester.pumpAndSettle();

      expect(find.text('desconocida:/ajustes'), findsOneWidget);
    });

    testWidgets('an unknown route keeps the Situation Room underneath', (
      tester,
    ) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);

      wired.controller.restore(UnknownAppPath(Uri.parse('/ajustes')));
      await tester.pumpAndSettle();

      expect(find.text('sala', skipOffstage: false), findsOneWidget);
    });
  });

  group('abrir y volver', () {
    testWidgets('returning to the Situation Room pops the detail page', (
      tester,
    ) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);
      wired.controller.openCase('isdal');
      await tester.pumpAndSettle();

      wired.controller.showSituationRoom();
      await tester.pumpAndSettle();

      expect(find.text('detalle:isdal'), findsNothing);
    });

    testWidgets('opening another case replaces the detail page', (
      tester,
    ) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);
      wired.controller.openCase('isdal');
      await tester.pumpAndSettle();

      wired.controller.openCase('somerton');
      await tester.pumpAndSettle();

      expect(find.text('detalle:isdal'), findsNothing);
    });

    testWidgets('opening another case shows the new one', (tester) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);
      wired.controller.openCase('isdal');
      await tester.pumpAndSettle();

      wired.controller.openCase('somerton');
      await tester.pumpAndSettle();

      expect(find.text('detalle:somerton'), findsOneWidget);
    });

    testWidgets('a system pop returns to the Situation Room', (tester) async {
      final wired = _wire();
      await _pumpRouter(tester, wired.delegate);
      wired.controller.openCase('isdal');
      await tester.pumpAndSettle();

      await wired.delegate.popRoute();
      await tester.pumpAndSettle();

      expect(wired.controller.path, isA<SituationRoomPath>());
    });
  });

  group('historial sin duplicados', () {
    test('restoring the same path does not notify', () {
      final controller = AppRouteController();
      addTearDown(controller.dispose);
      controller.openCase('isdal');
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.restore(const CaseDetailPath('isdal'));

      // Atrás y Adelante entran por aquí. Notificar sin cambio haría que el
      // delegate reemitiera la misma configuración y el historial creciera
      // solo, dejando el botón Atrás atascado.
      expect(notifications, 0);
    });

    test('restoring a different path does notify', () {
      final controller = AppRouteController();
      addTearDown(controller.dispose);
      controller.openCase('isdal');
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.restore(const CaseDetailPath('somerton'));

      expect(notifications, 1);
    });

    test('opening the case already open does not notify', () {
      final controller = AppRouteController();
      addTearDown(controller.dispose);
      controller.openCase('isdal');
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.openCase('isdal');

      expect(notifications, 0);
    });

    test('the delegate reports the current route as its configuration', () {
      final wired = _wire();
      wired.controller.openCase('isdal');

      // Es lo que el motor lee para reescribir la barra de direcciones.
      expect(
        wired.delegate.currentConfiguration,
        const CaseDetailPath('isdal'),
      );
    });

    test('setNewRoutePath moves the controller', () async {
      final wired = _wire();

      await wired.delegate.setNewRoutePath(const CaseDetailPath('isdal'));

      expect(wired.controller.path, const CaseDetailPath('isdal'));
    });
  });
}
