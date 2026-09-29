import 'dart:convert';

import '../domain/case_draft.dart';

/// Copia de seguridad de los borradores, en las dos direcciones.
///
/// **Por qué existe.** Los borradores viven en el `localStorage` del navegador
/// y ahí no los protege nadie: basta con limpiar datos de navegación, cambiar
/// de equipo o reinstalar el navegador para perder meses de investigación. El
/// exportador de casos no cubre este hueco porque sólo sabe sacar un caso
/// TERMINADO, y el trabajo largo vive precisamente en borradores a medias.
///
/// Se usa el mismo sobre versionado que la persistencia local, así que una
/// copia es literalmente lo que el navegador guarda.

/// Versión del formato de copia. Debe seguir a la del almacén local.
const int kDraftsBackupSchemaVersion = 1;

/// Resultado de leer una copia: o borradores, o un motivo por el que no.
///
/// No hay estado intermedio a propósito: una importación a medias dejaría al
/// usuario sin saber qué entró y qué no.
class DraftsBackupResult {
  const DraftsBackupResult.drafts(this.drafts) : error = null;
  const DraftsBackupResult.failed(this.error) : drafts = const [];

  final List<CaseDraft> drafts;

  /// Explicación en castellano y para leer, no un código.
  final String? error;
}

/// Serializa [drafts] en el texto que se guarda como copia.
///
/// Indentado a dos espacios porque acaba en un fichero que alguien puede abrir
/// y mirar; una copia ilegible invita a no revisarla nunca.
String encodeDraftsBackup(List<CaseDraft> drafts) {
  return const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': kDraftsBackupSchemaVersion,
    'drafts': [for (final draft in drafts) draft.toJson()],
  });
}

/// Lee una copia pegada por el usuario.
///
/// Falla entera antes que aceptar la mitad: mejor decir "esto no vale" que
/// dejar borradores truncados que parecen buenos.
DraftsBackupResult decodeDraftsBackup(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const DraftsBackupResult.failed(
      'Eso no parece una copia de seguridad. Pega el texto completo, desde la '
      'primera llave hasta la última.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const DraftsBackupResult.failed(
      'El texto es válido pero no es una copia de borradores.',
    );
  }

  final version = decoded['schemaVersion'];
  if (version is! int || version > kDraftsBackupSchemaVersion) {
    // Un formato posterior puede dar otro significado a las mismas claves.
    // Leerlo a medias es peor que reconocer que no se sabe leer.
    return const DraftsBackupResult.failed(
      'Esta copia es de una versión más nueva de la aplicación. Actualiza '
      'antes de restaurarla.',
    );
  }

  final entries = decoded['drafts'];
  if (entries is! List) {
    return const DraftsBackupResult.failed(
      'La copia no contiene ningún borrador.',
    );
  }

  final drafts = <CaseDraft>[];
  for (final entry in entries) {
    if (entry is! Map<String, dynamic>) {
      return const DraftsBackupResult.failed(
        'La copia tiene un borrador con un formato que no se reconoce.',
      );
    }
    try {
      drafts.add(CaseDraft.fromJson(entry));
    } on Object {
      return const DraftsBackupResult.failed(
        'La copia tiene un borrador incompleto o dañado. No se ha importado '
        'nada.',
      );
    }
  }
  return DraftsBackupResult.drafts(List.unmodifiable(drafts));
}

/// Resultado de fundir una copia con los borradores del equipo.
///
/// Lleva las cuentas para que la interfaz diga la verdad: cuántos borradores
/// han entrado y cuántos se han quedado con la versión local.
class DraftsMergeResult {
  const DraftsMergeResult({
    required this.drafts,
    required this.added,
    required this.keptLocal,
  });

  /// La lista completa tras fundir, lista para guardar.
  final List<CaseDraft> drafts;

  /// Borradores de la copia que no existían en el equipo y se han añadido.
  final int added;

  /// Borradores que ya existían en el equipo con OTRO contenido: se conserva
  /// la versión local y la de la copia se descarta.
  final int keptLocal;
}

/// Funde los borradores de una copia con los que ya hay.
///
/// **Nunca borra ni sustituye.** Un borrador que sólo existe en el equipo se
/// conserva, y uno que coincide por `draftId` también: una copia vieja del
/// navegador no puede deshacer en silencio lo editado después en este equipo.
/// Si la versión de la copia es distinta se cuenta en
/// [DraftsMergeResult.keptLocal]; si es idéntica no es un conflicto.
DraftsMergeResult mergeDrafts({
  required List<CaseDraft> current,
  required List<CaseDraft> incoming,
}) {
  final byId = {for (final draft in current) draft.draftId: draft};
  var added = 0;
  var keptLocal = 0;
  for (final draft in incoming) {
    final local = byId[draft.draftId];
    if (local == null) {
      byId[draft.draftId] = draft;
      added++;
    } else if (!_sameJson(local.toJson(), draft.toJson())) {
      keptLocal++;
    }
  }
  return DraftsMergeResult(
    drafts: List.unmodifiable(byId.values),
    added: added,
    keptLocal: keptLocal,
  );
}

/// Igualdad profunda de dos valores JSON (mapas, listas y escalares).
///
/// Compara por contenido, no por el orden de las claves: dos borradores
/// leídos por caminos distintos pueden serializar igual en otro orden.
bool _sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || !_sameJson(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_sameJson(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}
