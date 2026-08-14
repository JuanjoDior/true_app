import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_route_controller.dart';
import 'app_route_path.dart';

/// Construye la página de detalle de un caso a partir de su slug.
typedef CaseDetailBuilder = Widget Function(BuildContext context, String slug);

/// Construye la página de ruta no encontrada, conservando la URI original.
typedef RouteNotFoundBuilder = Widget Function(BuildContext context, Uri uri);

/// Convierte el estado de ruta en una pila de páginas [diseño §7.3].
///
/// **Las páginas llegan por inyección.** No es ceremonia: es lo que permite que
/// esta pieza exista y se pruebe entera sin conocer todavía `CaseDetailPage`, y
/// sin dejar widgets marcador muertos esperando a que alguien los active.
///
/// El detalle se apila ENCIMA de la raíz, nunca en su lugar. Por eso un enlace
/// directo enseña el expediente aunque debajo estuviera el workspace de intake,
/// y volver revela lo que ya hubiera allí sin que el router decida nada.
class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  AppRouterDelegate({
    required this.controller,
    required this.situationRoomBuilder,
    required this.caseDetailBuilder,
    required this.routeNotFoundBuilder,
  }) {
    controller.addListener(notifyListeners);
  }

  final AppRouteController controller;
  final WidgetBuilder situationRoomBuilder;
  final CaseDetailBuilder caseDetailBuilder;
  final RouteNotFoundBuilder routeNotFoundBuilder;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  AppRoutePath get currentConfiguration => controller.path;

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) {
    controller.restore(configuration);
    return SynchronousFuture(null);
  }

  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _pages(),
      // La página se quita cuando el sistema ya la ha retirado; el estado de
      // ruta se pone al día detrás, sin volver a empujar nada.
      onDidRemovePage: (page) {
        if (page.key != const ValueKey('situation-room')) {
          controller.showSituationRoom();
        }
      },
    );
  }

  List<Page<void>> _pages() {
    final root = MaterialPage<void>(
      key: const ValueKey('situation-room'),
      child: Builder(builder: situationRoomBuilder),
    );

    return switch (controller.path) {
      SituationRoomPath() => [root],
      CaseDetailPath(:final slug) => [
        root,
        MaterialPage<void>(
          // La clave lleva el slug: abrir otro caso sustituye la página en vez
          // de reutilizar su estado con datos ajenos.
          key: ValueKey('case-detail-$slug'),
          child: Builder(
            builder: (context) => caseDetailBuilder(context, slug),
          ),
        ),
      ],
      UnknownAppPath(:final uri) => [
        root,
        MaterialPage<void>(
          key: ValueKey('route-not-found-$uri'),
          child: Builder(
            builder: (context) => routeNotFoundBuilder(context, uri),
          ),
        ),
      ],
    };
  }
}
