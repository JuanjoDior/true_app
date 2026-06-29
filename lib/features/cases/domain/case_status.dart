/// Estado de investigación de un caso del archivo.
///
/// Es un eje independiente de la categoría: un caso puede ser un asesino en
/// serie y, a la vez, estar resuelto o seguir abierto.
enum CaseStatus {
  open,
  solved,
  inProgress;

  factory CaseStatus.fromJson(String value) {
    return switch (value) {
      'open' => CaseStatus.open,
      'solved' => CaseStatus.solved,
      'inProgress' => CaseStatus.inProgress,
      _ => throw ArgumentError.value(value, 'value', 'Unknown case status'),
    };
  }

  /// Etiqueta corta usada en los chips de filtro de estado.
  String get label {
    return switch (this) {
      CaseStatus.open => 'Sin resolver',
      CaseStatus.solved => 'Resuelto',
      CaseStatus.inProgress => 'En investigación',
    };
  }
}
