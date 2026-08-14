import 'package:flutter/foundation.dart';

import 'app_navigation.dart';
import 'app_route_path.dart';

/// Dueño del estado de ruta [diseño §7.3].
///
/// **No escribe `workspaceProvider` ni la selección del mapa, y no puede**: no
/// los importa. Esa ausencia es la regla, no un descuido. `workspaceProvider`
/// ya tiene un dueño en la interfaz; un router que lo reescribiera en cada ruta
/// raíz sería un segundo dueño, y dos dueños acaban discrepando sobre qué
/// enseña `/`.
class AppRouteController extends ChangeNotifier implements AppNavigation {
  AppRoutePath _path = const SituationRoomPath();

  AppRoutePath get path => _path;

  @override
  void openCase(String slug) => _moveTo(CaseDetailPath(slug));

  @override
  void showSituationRoom() => _moveTo(const SituationRoomPath());

  /// Entrada desde el motor de rutas: enlace directo, Atrás y Adelante.
  void restore(AppRoutePath path) => _moveTo(path);

  /// Cambia de ruta **sólo si de verdad cambia**.
  ///
  /// Atrás y Adelante entran por aquí. Notificar sin cambio haría que el
  /// delegate reemitiera la misma configuración, el historial creciera solo y
  /// el botón Atrás se quedara atascado en el mismo sitio.
  void _moveTo(AppRoutePath next) {
    if (_path == next) {
      return;
    }
    _path = next;
    notifyListeners();
  }
}
