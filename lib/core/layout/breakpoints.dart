/// Fuente única de umbrales de ancho para elegir entre distribuciones de
/// pantalla ancha y estrecha. El directorio y el workspace de intake consumen
/// este archivo en vez de repetir literales sueltos.
abstract final class Breakpoints {
  /// Directorio: por debajo, la hoja ocupa el ancho entero; a partir de aquí,
  /// se acota a 720px.
  static const double sidePanel = 880;

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
