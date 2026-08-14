import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/cases/presentation/case_detail_page.dart';
import '../features/home/presentation/home_page.dart';
import 'navigation/app_navigation_scope.dart';
import 'navigation/app_route_controller.dart';
import 'navigation/app_route_information_parser.dart';
import 'navigation/app_router_delegate.dart';
import 'navigation/route_not_found_page.dart';

/// Raíz de la aplicación, con las rutas hash activas [diseño §7.1].
///
/// **Es `StatefulWidget` por una razón concreta**: el controlador y el delegate
/// tienen que crearse UNA vez y vivir mientras viva el widget. Creados en un
/// `build` se recrearían en cada reconstrucción, perdiendo la ruta actual y
/// dejando al motor de rutas hablando con un objeto muerto.
class TrueCrimeApp extends StatefulWidget {
  const TrueCrimeApp({super.key, this.initialLocation});

  /// Ruta de arranque. Sólo la usan los tests; en producción la trae la barra
  /// de direcciones del navegador.
  final String? initialLocation;

  @override
  State<TrueCrimeApp> createState() => _TrueCrimeAppState();
}

class _TrueCrimeAppState extends State<TrueCrimeApp> {
  late final AppRouteController _controller = AppRouteController();
  late final AppRouterDelegate _delegate = AppRouterDelegate(
    controller: _controller,
    situationRoomBuilder: (context) => const TrueCrimeHomePage(),
    caseDetailBuilder: (context, slug) =>
        CaseDetailPage(slug: slug, navigation: _controller),
    routeNotFoundBuilder: (context, uri) =>
        RouteNotFoundPage(uri: uri, navigation: _controller),
  );

  @override
  void dispose() {
    _delegate.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationScope(navigation: _controller, child: _buildApp());
  }

  Widget _buildApp() {
    return MaterialApp.router(
      title: 'true_app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      routerDelegate: _delegate,
      routeInformationParser: AppRouteInformationParser(),
      // `null` significa "usa el de la plataforma", que es el que lee la barra
      // de direcciones de verdad. Pasar uno propio SIEMPRE hacía que la
      // aplicación desplegada arrancara en `/` ignorando la URL, así que
      // cualquier enlace directo a un expediente aterrizaba en la Sala con el
      // hash borrado. Sólo se sustituye cuando un test fija la ruta.
      routeInformationProvider: switch (widget.initialLocation) {
        null => null,
        final location => PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse(location)),
        ),
      },
    );
  }
}
