import 'dart:convert';

import '../domain/case_draft.dart';
import '../domain/case_source.dart';

/// Convierte un borrador en el JSON que consume `assets/data/cases.json`.
///
/// Es el único puente entre el borrador local de Iván y el catálogo
/// publicado: no hay backend ni CMS, así que el flujo es exportar, pegar en
/// el asset y commitear. Por eso el contrato que importa es que lo emitido
/// vuelva a entrar por `TrueCrimeCase.fromJson` sin perder nada.

/// Reemplazos de caracteres acentuados y ligaduras habituales en castellano
/// y en los idiomas de los casos ya publicados.
const Map<String, String> _diacritics = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c', 'ß': 'ss', 'æ': 'ae',
};

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

/// Mapea el borrador al esquema publicado de `TrueCrimeCase`.
///
/// Los campos que el borrador todavía no captura (tags, víctima, cronología,
/// destacados) se omiten: `fromJson` los trata como opcionales y se editan a
/// mano en el asset si hacen falta.
Map<String, dynamic> draftToCaseJson(CaseDraft draft) {
  final title = draft.title?.trim() ?? '';
  final slug = caseSlug(title);

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
    'latitude': draft.latitude,
    'longitude': draft.longitude,
    // `TrueCrimeCase.summary` no admite null.
    'summary': draft.summary?.trim() ?? '',
    'tags': const <String>[],
    'sources': sources,
    'status': draft.status?.name,
    // Las fotos aún no se pintan en el expediente publicado, pero viajan en
    // el export para no perder el trabajo ya hecho en el borrador.
    if (photos.isNotEmpty) 'photos': photos,
  };
}

/// Texto listo para pegar en `assets/data/cases.json`: indentado a dos
/// espacios y sin escapar los acentos, para que el asset siga siendo legible.
String encodeDraftAsCaseJson(CaseDraft draft) {
  return const JsonEncoder.withIndent('  ').convert(draftToCaseJson(draft));
}
