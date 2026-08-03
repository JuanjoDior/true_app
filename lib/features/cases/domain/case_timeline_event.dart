/// Color semántico de cada hito de la cronología.
///
/// Replica los tonos de la "Sala de Situación": el hecho inicial en rojo, el
/// proceso intermedio en granate, lo abierto en azul y lo resuelto en verde.
enum CaseTimelineKind {
  initial,
  process,
  open,
  solved;

  factory CaseTimelineKind.fromJson(String value) {
    final kind = CaseTimelineKind.tryFromJson(value);
    if (kind == null) {
      throw ArgumentError.value(value, 'value', 'Unknown timeline kind');
    }
    return kind;
  }

  /// Variante tolerante para el borrador, donde un valor desconocido no debe
  /// dejar el caso inaccesible: se trata como "sin clasificar".
  static CaseTimelineKind? tryFromJson(String value) {
    return switch (value) {
      'red' || 'initial' => CaseTimelineKind.initial,
      'mid' || 'process' => CaseTimelineKind.process,
      'open' => CaseTimelineKind.open,
      'solved' => CaseTimelineKind.solved,
      _ => null,
    };
  }

  String get label {
    return switch (this) {
      CaseTimelineKind.initial => 'Hecho inicial',
      CaseTimelineKind.process => 'Investigación',
      CaseTimelineKind.open => 'Sigue abierto',
      CaseTimelineKind.solved => 'Resolución',
    };
  }
}

/// Un hito de la cronología verificada de un caso.
class CaseTimelineEvent {
  const CaseTimelineEvent({
    required this.title,
    required this.date,
    required this.kind,
  });

  final String title;
  final String date;
  final CaseTimelineKind kind;

  factory CaseTimelineEvent.fromJson(Map<String, dynamic> json) {
    return CaseTimelineEvent(
      title: json['title'] as String,
      date: json['date'] as String,
      kind: CaseTimelineKind.fromJson(json['kind'] as String),
    );
  }
}
