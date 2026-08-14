/// Capítulos editoriales de un caso: cuatro tipos fijos y opcionales que
/// viajan iguales por el borrador local y por el catálogo publicado
/// [spec: case-editorial-chapters].
///
/// El conjunto es cerrado a propósito. No hay títulos editables, ni índice de
/// orden, ni identificadores libres: añadir un tipo es tocar este enum, no
/// dato de usuario. Eso mantiene el orden editorial y la validación
/// predecibles.
library;

/// Los cuatro tipos admitidos, declarados en el orden editorial en el que se
/// presentan siempre, sea cual sea el orden de autoría o de decodificación.
enum CaseChapterType { background, events, investigation, currentStatus }

/// Un capítulo con contenido significativo. Sólo existe para los capítulos que
/// se muestran: los vacíos no llegan a construirse.
final class CaseChapter {
  const CaseChapter({required this.type, required this.content});

  final CaseChapterType type;
  final String content;

  @override
  bool operator ==(Object other) =>
      other is CaseChapter && other.type == type && other.content == content;

  @override
  int get hashCode => Object.hash(type, content);

  @override
  String toString() => 'CaseChapter(${type.name}, ${content.length} chars)';
}

/// Colección inmutable con un hueco por tipo.
///
/// Cuatro campos con nombre en vez de una lista: así el modelo hace imposible
/// repetir un tipo o reordenarlos, sin necesidad de validarlo en cada capa.
final class CaseChapters {
  const CaseChapters({
    this.background,
    this.events,
    this.investigation,
    this.currentStatus,
  });

  final String? background;
  final String? events;
  final String? investigation;
  final String? currentStatus;

  /// Un contenido cuenta sólo si tiene algún carácter que no sea espacio.
  ///
  /// Comprobarlo con `trim` decide la inclusión; nunca reescribe la prosa. El
  /// texto que sí cuenta se conserva verbatim, con sus saltos de línea y sus
  /// espacios de sangría [diseño §4.3].
  static bool _isMeaningful(String? content) =>
      content != null && content.trim().isNotEmpty;

  /// Los capítulos con contenido, siempre en orden editorial.
  List<CaseChapter> get orderedMeaningful {
    final chapters = <CaseChapter>[];
    for (final type in CaseChapterType.values) {
      final content = contentFor(type);
      if (_isMeaningful(content)) {
        chapters.add(CaseChapter(type: type, content: content!));
      }
    }
    return List.unmodifiable(chapters);
  }

  String? contentFor(CaseChapterType type) => switch (type) {
    CaseChapterType.background => background,
    CaseChapterType.events => events,
    CaseChapterType.investigation => investigation,
    CaseChapterType.currentStatus => currentStatus,
  };

  /// Devuelve una copia con ese tipo actualizado.
  ///
  /// Un contenido en blanco vacía el hueco en lugar de guardarlo: borrar el
  /// texto de un capítulo equivale a no tenerlo.
  CaseChapters withContent(CaseChapterType type, String content) {
    final value = _isMeaningful(content) ? content : null;
    return CaseChapters(
      background: type == CaseChapterType.background ? value : background,
      events: type == CaseChapterType.events ? value : events,
      investigation: type == CaseChapterType.investigation
          ? value
          : investigation,
      currentStatus: type == CaseChapterType.currentStatus
          ? value
          : currentStatus,
    );
  }

  static CaseChapterType? _typeFromWire(Object? value) {
    if (value is! String) return null;
    for (final type in CaseChapterType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  /// Decodificación tolerante: los capítulos son opcionales, así que esto no
  /// lanza nunca [diseño §4.4].
  ///
  /// Cada entrada se juzga por separado. Una entrada ignorada **no consume su
  /// hueco**: sólo una entrada aceptada convierte en duplicada a otra posterior
  /// del mismo tipo. Un campo core malformado queda fuera de esta tolerancia y
  /// sigue fallando en su propio decodificador.
  factory CaseChapters.fromJson(Object? value) {
    if (value is! List) return const CaseChapters();

    final accepted = <CaseChapterType, String>{};
    for (final entry in value) {
      if (entry is! Map) continue;
      final type = _typeFromWire(entry['type']);
      if (type == null || accepted.containsKey(type)) continue;
      final content = entry['content'];
      if (content is! String || !_isMeaningful(content)) continue;
      accepted[type] = content;
    }

    return CaseChapters(
      background: accepted[CaseChapterType.background],
      events: accepted[CaseChapterType.events],
      investigation: accepted[CaseChapterType.investigation],
      currentStatus: accepted[CaseChapterType.currentStatus],
    );
  }

  /// Sólo los capítulos con contenido, en orden editorial. Una colección sin
  /// nada significativo produce una lista vacía, y quien serializa omite
  /// entonces el miembro entero.
  List<Map<String, dynamic>> toJson() => [
    for (final chapter in orderedMeaningful)
      {'type': chapter.type.name, 'content': chapter.content},
  ];

  @override
  bool operator ==(Object other) =>
      other is CaseChapters &&
      other.background == background &&
      other.events == events &&
      other.investigation == investigation &&
      other.currentStatus == currentStatus;

  @override
  int get hashCode =>
      Object.hash(background, events, investigation, currentStatus);
}
