/// Fuente única de umbrales de ancho para elegir entre distribuciones de
/// pantalla ancha y estrecha. La Sala de Situación pública y el workspace de
/// intake consumen este archivo en vez de repetir literales sueltos.
///
/// Los cuatro umbrales de la Sala (`sidePanel`/`topBarFull`/`widePanel`/
/// `navRail`) NO se colapsan en una única escala: cada uno responde a una
/// decisión distinta (topología, densidad de contenido, tamaño de panel,
/// affordance de chrome) y un único punto de corte cambiaría el resultado
/// visible en algún punto del rango 880–1100 en una pantalla ya publicada.
abstract final class Breakpoints {
  /// Sala: por debajo, `_MobileBody` (mapa a pantalla completa); a partir de
  /// aquí, `_DesktopBody` (rail + mapa + panel lateral).
  static const double sidePanel = 880;

  /// Sala: por debajo, la barra superior oculta métricas y selector global.
  static const double topBarFull = 980;

  /// Sala: por debajo, el panel lateral mide 320px; a partir de aquí, 362px.
  static const double widePanel = 1024;

  /// Sala: por debajo, el rail lateral de iconos no se muestra.
  static const double navRail = 1100;

  /// Intake: por debajo, el workspace pasa de tres columnas a una sola con
  /// hojas superpuestas para lista de borradores y previsualización.
  static const double intakeThreePane = 1024;

  /// Fila de campos del formulario de intake: por debajo, la fila pasa de
  /// `Row` a `Column` apilada.
  static const double formRowStack = 520;
}
