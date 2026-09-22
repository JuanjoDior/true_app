import 'dart:convert';

import '../domain/case_draft.dart';
import '../domain/case_source.dart';
import '../domain/case_timeline_event.dart';

/// Convierte un borrador en el JSON que consume `assets/data/cases.json`.
///
/// Es el único puente entre el borrador local de Iván y el catálogo
/// publicado: no hay backend ni CMS, así que el flujo es exportar, pegar en
/// el asset y commitear. Por eso el contrato que importa es que lo emitido
/// vuelva a entrar por `TrueCrimeCase.fromJson` sin perder nada.

/// Reemplazos de caracteres acentuados y ligaduras habituales en castellano
/// y en los idiomas de los casos ya publicados.
const Map<String, String> _diacritics = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'õ': 'o',
  'ø': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ß': 'ss',
  'æ': 'ae',
};

/// Recorta la precisión de una coordenada a cinco decimales, algo más de un
/// metro.
///
/// Marcar un punto en el mapa produce quince decimales de precisión que nadie
/// tiene, y el catálogo es un archivo que se lee y se edita a mano.
double? _roundCoordinate(double? value) {
  if (value == null) {
    return null;
  }
  return double.parse(value.toStringAsFixed(5));
}

/// Slug estable a partir del título editorial: minúsculas, sin acentos y con
/// guiones. Es la identidad pública del caso (`id` y `slug`).
String caseSlug(String title) {
  final lowered = title.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lowered.split('')) {
    buffer.write(_diacritics[char] ?? char);
  }

  final slug = buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  // Un título compuesto sólo de signos dejaría el slug vacío y produciría un
  // caso sin identidad.
  return slug.isEmpty ? 'caso-sin-titulo' : slug;
}

/// Devuelve un slug libre a partir de [base], añadiendo `-2`, `-3`… si ya está
/// ocupado.
///
/// Dos casos con el mismo `id` romperían la selección en el mapa y los casos
/// relacionados, que se resuelven por identidad [Diseño #4]. Y títulos que sólo
/// se diferencian en acentos o puntuación producen el mismo slug base, así que
/// la colisión no es rara.
String uniqueCaseSlug(String base, Set<String> taken) {
  if (!taken.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (taken.contains('$base-$suffix')) {
    suffix++;
  }
  return '$base-$suffix';
}

/// Mapea el borrador al esquema publicado de `TrueCrimeCase`.
///
/// [takenSlugs] son los slugs que ya existen —los del catálogo publicado y los
/// de los demás borradores—, para no emitir una identidad repetida.
Map<String, dynamic> draftToCaseJson(
  CaseDraft draft, {
  Set<String> takenSlugs = const {},
}) {
  final title = draft.title?.trim() ?? '';
  final slug = uniqueCaseSlug(caseSlug(title), takenSlugs);

  final sources = <Map<String, dynamic>>[
    for (final link in draft.links)
      if (link.url?.trim().isNotEmpty ?? false)
        {
          'id': link.url!.trim(),
          'title': link.title?.trim().isNotEmpty ?? false
              ? link.title!.trim()
              : link.url!.trim(),
          'url': link.url!.trim(),
          // El catálogo publicado sólo distingue investigación y podcast;
          // vídeo, documento y publicación son material de investigación.
          'kind': link.kind == DraftLinkKind.podcast
              ? CaseSourceKind.podcast.name
              : CaseSourceKind.investigation.name,
        },
  ];

  final timeline = <Map<String, dynamic>>[
    for (final event in draft.timeline)
      if ((event.title?.trim().isNotEmpty ?? false) ||
          (event.date?.trim().isNotEmpty ?? false))
        {
          'title': event.title?.trim() ?? '',
          'date': event.date?.trim() ?? '',
          // `CaseTimelineEvent.fromJson` exige el tipo; un hito sin clasificar
          // se publica como parte de la investigación.
          'kind': (event.kind ?? CaseTimelineKind.process).name,
        },
  ];

  final photos = <Map<String, dynamic>>[
    for (final photo in draft.photos)
      if (photo.url?.trim().isNotEmpty ?? false)
        {
          'url': photo.url!.trim(),
          if (photo.caption?.trim().isNotEmpty ?? false)
            'caption': photo.caption!.trim(),
        },
  ];

  return {
    'id': slug,
    'slug': slug,
    'title': title,
    'category': draft.category?.name,
    'country': draft.country?.trim(),
    'countryCode': draft.countryCode?.trim().toUpperCase(),
    'regionOrCity': draft.regionOrCity?.trim(),
    'year': draft.year,
    'latitude': _roundCoordinate(draft.latitude),
    'longitude': _roundCoordinate(draft.longitude),
    // `TrueCrimeCase.summary` no admite null.
    'summary': draft.summary?.trim() ?? '',
    'tags': draft.tags,
    'sources': sources,
    'status': draft.status?.name,
    if (draft.victim?.trim().isNotEmpty ?? false)
      'victim': draft.victim!.trim(),
    if (timeline.isNotEmpty) 'timeline': timeline,
    // Las fotos se pintan en el expediente publicado
    // (case_dossier_content.dart:160-164).
    if (photos.isNotEmpty) 'photos': photos,
    // Única excepción deliberada al recorte que aplica el resto del
    // exportador: los capítulos son prosa editorial y su sangría y sus saltos
    // de línea son intencionados [diseño §4.3]. `toJson` ya devuelve sólo los
    // significativos y en orden editorial.
    if (draft.chapters.orderedMeaningful.isNotEmpty)
      'chapters': draft.chapters.toJson(),
    if (draft.featuredRank != null) 'featuredRank': draft.featuredRank,
    if (draft.relevanceRank != null) 'relevanceRank': draft.relevanceRank,
  };
}

/// Texto listo para pegar en `assets/data/cases.json`: indentado a dos
/// espacios y sin escapar los acentos, para que el asset siga siendo legible.
String encodeDraftAsCaseJson(
  CaseDraft draft, {
  Set<String> takenSlugs = const {},
}) {
  return const JsonEncoder.withIndent(
    '  ',
  ).convert(draftToCaseJson(draft, takenSlugs: takenSlugs));
}

/// Qué le pasó a un borrador seleccionado dentro del lote.
enum CatalogMergeOutcome { added, replaced }

/// El destino de un borrador dentro del catálogo fundido.
final class CatalogMergeEntry {
  const CatalogMergeEntry({
    required this.draftId,
    required this.title,
    required this.slug,
    required this.outcome,
    this.replacedTitle,
    this.droppedKeys = const <String>[],
  });

  final String draftId;
  final String title;

  /// Identidad pública asignada dentro de ESTE lote.
  final String slug;
  final CatalogMergeOutcome outcome;

  /// Título de la entrada publicada que se sustituye. Null si [outcome] es
  /// [CatalogMergeOutcome.added].
  final String? replacedTitle;

  /// Claves que la entrada publicada tenía y el borrador no puede expresar
  /// (`statusLabel`, un `featuredRank` que el borrador no rellena…). Se
  /// pierden al sustituirla, y por eso se enseñan ANTES de confirmar.
  final List<String> droppedKeys;
}

/// Catálogo completo más la traza de qué hizo el lote.
final class CatalogMergeResult {
  const CatalogMergeResult({required this.cases, required this.entries});

  /// Array completo, listo para sustituir `assets/data/cases.json`.
  final List<Map<String, dynamic>> cases;

  /// Un elemento por borrador seleccionado, en orden de selección.
  final List<CatalogMergeEntry> entries;

  Iterable<CatalogMergeEntry> get replacements =>
      entries.where((e) => e.outcome == CatalogMergeOutcome.replaced);
}

/// Decodifica el asset publicado sin perder nada: cada caso viaja tal y como
/// está escrito en el fichero.
///
/// Lanza [FormatException] si el texto no es un array de objetos. NO devuelve
/// una lista vacía ante un fallo: fundir sobre un catálogo vacío borraría
/// todo lo publicado — un catálogo ilegible nunca se trata como uno vacío.
List<Map<String, dynamic>> decodeCatalogPayload(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is! List) {
    throw const FormatException(
      'El catálogo publicado debe ser un array JSON de casos.',
    );
  }
  return decoded.map((item) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException(
        'Una entrada del catálogo publicado no es un objeto JSON.',
      );
    }
    return item;
  }).toList(growable: false);
}

/// Funde los borradores seleccionados en el catálogo cargado.
///
/// [catalog] llega decodificado por [decodeCatalogPayload]; [drafts] en el
/// orden en que se seleccionaron. Es pura: mismas entradas, mismo resultado.
///
/// Resolución de slugs secuencial dentro del lote: el slug de un borrador
/// anterior se añade al conjunto considerado para los siguientes. Un borrador
/// cuyo slug base ya está publicado y aún no ha sido reclamado por este
/// mismo lote SUSTITUYE esa entrada en su misma posición del array; en
/// cualquier otro caso se añade con un slug libre.
CatalogMergeResult mergeDraftsIntoCatalog({
  required List<Map<String, dynamic>> catalog,
  required List<CaseDraft> drafts,
}) {
  final taken = <String>{
    for (final entry in catalog)
      if (entry['slug'] is String) entry['slug'] as String,
  };
  final batchSlugs = <String>{};
  final cases = List<Map<String, dynamic>>.of(catalog);
  final entries = <CatalogMergeEntry>[];

  for (final draft in drafts) {
    final title = draft.title?.trim() ?? '';
    final base = caseSlug(title);

    if (taken.contains(base) && !batchSlugs.contains(base)) {
      // Sustitución: el mantenedor republica deliberadamente esta identidad.
      final index = cases.indexWhere((entry) => entry['slug'] == base);
      // `takenSlugs: const {}` es deliberado: reclamamos `base` a propósito,
      // no queremos que se le añada un sufijo.
      final json = draftToCaseJson(draft, takenSlugs: const {});
      final replaced = cases[index];
      final droppedKeys = replaced.keys
          .where((key) => !json.containsKey(key))
          .toList(growable: false);

      entries.add(
        CatalogMergeEntry(
          draftId: draft.draftId,
          title: title,
          slug: base,
          outcome: CatalogMergeOutcome.replaced,
          replacedTitle: replaced['title'] as String?,
          droppedKeys: droppedKeys,
        ),
      );
      cases[index] = json; // el índice se conserva
      taken.add(base);
      batchSlugs.add(base);
    } else {
      final json = draftToCaseJson(draft, takenSlugs: taken);
      final slug = json['slug'] as String;

      entries.add(
        CatalogMergeEntry(
          draftId: draft.draftId,
          title: title,
          slug: slug,
          outcome: CatalogMergeOutcome.added,
        ),
      );
      cases.add(json);
      taken.add(slug);
      batchSlugs.add(slug);
    }
  }

  return CatalogMergeResult(cases: cases, entries: entries);
}

/// Texto listo para sustituir `assets/data/cases.json`: dos espacios de
/// sangría y acentos sin escapar, como el resto del catálogo, con un único
/// salto de línea final para que el fichero producido sea un texto POSIX
/// bien formado.
String encodeMergedCatalog(CatalogMergeResult result) {
  final encoded = const JsonEncoder.withIndent('  ').convert(result.cases);
  return '$encoded\n';
}
