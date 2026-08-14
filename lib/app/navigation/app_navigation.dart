/// Lo único que una pantalla necesita saber para navegar.
///
/// Se inyecta como contrato y no como el controlador concreto para que las
/// pantallas no puedan leer el estado de ruta ni escribirlo por otras vías:
/// pueden pedir ir a un sitio, no husmear dónde están.
abstract interface class AppNavigation {
  /// Abre el expediente ampliado de [slug].
  void openCase(String slug);

  /// Vuelve a la raíz. Qué se ve allí — mapa o intake — lo decide el
  /// workspace, no esta llamada.
  void showSituationRoom();
}
