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
  ///
  /// Subido de 980 a 1040 al añadir el acceso al directorio: con el botón
  /// nuevo, la barra desbordaba 45px en el tramo 980–1024. Se recortan las
  /// métricas y no el acceso porque las métricas son decorativas y el acceso al
  /// archivo es funcional — y en el tramo 880–1100 no hay rail donde caiga.
  static const double topBarFull = 1040;

  /// Sala: por debajo, el panel lateral mide 320px; a partir de aquí, 362px.
  static const double widePanel = 1024;

  /// Sala: por debajo, el rail lateral de iconos no se muestra.
  static const double navRail = 1100;

  /// Intake: por debajo, el workspace pasa de tres columnas a una sola con
  /// hojas superpuestas para lista de borradores y previsualización.
  ///
  /// Subido de 1024 a 1200: la columna del medio pierde 260 (lista) + 380
  /// (preview) + 40 (padding propio) antes de que una sola fila de campos
  /// pueda respirar, así que entre 1024 y 1199 el "escritorio" de tres
  /// columnas apilaba TODAS las filas igual que el layout angosto, pero sin
  /// sus afordancias — la peor mezcla de ambos. 1200 es exactamente el punto
  /// en el que a la columna le queda `Breakpoints.formRowStack` (520) de
  /// sobra: 1200 − 260 − 380 − 40 = 520.
  static const double intakeThreePane = 1200;

  /// Fila de campos del formulario de intake: por debajo, la fila pasa de
  /// `Row` a `Column` apilada.
  static const double formRowStack = 520;
}
