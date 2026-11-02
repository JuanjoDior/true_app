/// Datos del expediente que aún no existen y deben mostrarse como pendientes.
///
/// Sólo lo usa la vista previa de un borrador: una cabecera no puede enseñar
/// «0», «Por confirmar» o «0.00° N» como si fueran datos reales. Con
/// [DossierPending.none] (el valor por defecto de cada componente) el
/// expediente público se pinta exactamente igual que siempre.
class DossierPending {
  const DossierPending({
    this.year = false,
    this.category = false,
    this.status = false,
    this.region = false,
    this.country = false,
    this.coordinates = false,
    this.summary = false,
    this.victims = false,
  });

  static const none = DossierPending();

  /// Texto que ocupa el lugar de un dato pendiente.
  static const placeholder = 'pendiente';

  final bool year;
  final bool category;
  final bool status;
  final bool region;
  final bool country;
  final bool coordinates;
  final bool summary;
  final bool victims;

  bool get place => region || country;
}
