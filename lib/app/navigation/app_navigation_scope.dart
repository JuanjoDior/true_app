import 'package:flutter/widgets.dart';

import 'app_navigation.dart';

/// Pone [AppNavigation] al alcance de cualquier pantalla.
///
/// Se usa un `InheritedWidget` y no un provider a propósito: el paquete de
/// navegación no conoce Riverpod, y así sigue sin conocerlo. Lo que se reparte
/// es el CONTRATO, no el controlador, de modo que una pantalla puede pedir ir a
/// un sitio pero no leer ni reescribir el estado de ruta por su cuenta.
class AppNavigationScope extends InheritedWidget {
  const AppNavigationScope({
    super.key,
    required this.navigation,
    required super.child,
  });

  final AppNavigation navigation;

  /// La navegación vigente, o `null` fuera del scope.
  ///
  /// Devuelve nullable porque hay superficies que se montan sueltas en tests y
  /// en composiciones parciales. Un punto de entrada sin navegación detrás se
  /// oculta en vez de reventar.
  static AppNavigation? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppNavigationScope>()
        ?.navigation;
  }

  @override
  bool updateShouldNotify(AppNavigationScope oldWidget) =>
      oldWidget.navigation != navigation;
}
