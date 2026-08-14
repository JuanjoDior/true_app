import 'case_category.dart';
import 'case_chapter.dart';
import 'case_status.dart';
import 'case_timeline_event.dart';
import 'resolved_place.dart';

/// Borrador de caso de Iván: v1 solo campos base, todos opcionales salvo el
/// identificador local. Tolerante a campos ausentes para permitir crecimiento
/// futuro (cronología, personas, ubicaciones) sin romper drafts guardados.
class CaseDraft {
  const CaseDraft({
    required this.draftId,
    this.title,
    this.category,
    this.year,
    this.status,
    this.summary,
    this.country,
    this.countryCode,
    this.regionOrCity,
    this.latitude,
    this.longitude,
    this.victim,
    this.tags = const <String>[],
    this.timeline = const <DraftTimelineEvent>[],
    this.links = const <DraftLink>[],
    this.photos = const <DraftPhoto>[],
    this.chapters = const CaseChapters(),
  });

  /// Identidad local estable del borrador, independiente del título.
  final String draftId;
  final String? title;
  final CaseCategory? category;
  final int? year;
  final CaseStatus? status;
  final String? summary;

  /// Ubicación del caso. Es obligatoria para publicar: sin coordenadas el
  /// caso no puede pintarse en el mapa, que es el núcleo del producto.
  final String? country;

  /// Código ISO de dos letras del país, p. ej. `ES`.
  final String? countryCode;
  final String? regionOrCity;
  final double? latitude;
  final double? longitude;

  /// Descripción de la víctima o víctimas, nombradas con respeto. Es un texto
  /// editorial ("Al menos 5 víctimas confirmadas"), no un nombre suelto.
  final String? victim;

  /// Etiquetas del caso, en minúsculas como el resto del catálogo.
  final List<String> tags;

  /// Cronología verificada del caso.
  final List<DraftTimelineEvent> timeline;
  final List<DraftLink> links;

  /// Fotografías del caso: sólo URLs ya alojadas, sin subida de archivos
  /// (política "sin backend, sin CMS") [Diseño #14].
  final List<DraftPhoto> photos;

  /// Capítulos editoriales de formato largo. Aditivo: los borradores guardados
  /// antes de existir este campo decodifican a una colección vacía.
  final CaseChapters chapters;

  CaseDraft copyWith({
    String? title,
    CaseCategory? category,
    int? year,
    CaseStatus? status,
    String? summary,
    String? country,
    String? countryCode,
    String? regionOrCity,
    double? latitude,
    double? longitude,
    String? victim,
    List<String>? tags,
    List<DraftTimelineEvent>? timeline,
    List<DraftLink>? links,
    List<DraftPhoto>? photos,
    CaseChapters? chapters,
  }) {
    return CaseDraft(
      draftId: draftId,
      title: title ?? this.title,
      category: category ?? this.category,
      year: year ?? this.year,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      regionOrCity: regionOrCity ?? this.regionOrCity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      victim: victim ?? this.victim,
      tags: tags ?? this.tags,
      timeline: timeline ?? this.timeline,
      links: links ?? this.links,
      photos: photos ?? this.photos,
      chapters: chapters ?? this.chapters,
    );
  }

  /// Asienta la ubicación resuelta a partir del punto marcado en el mapa.
  ///
  /// A diferencia de [copyWith], un lugar sin municipio BORRA el anterior:
  /// conservarlo dejaría la ciudad de un punto junto al país de otro.
  CaseDraft withResolvedPlace(ResolvedPlace place) {
    return CaseDraft(
      draftId: draftId,
      title: title,
      category: category,
      year: year,
      status: status,
      summary: summary,
      country: place.country,
      countryCode: place.countryCode,
      regionOrCity: place.regionOrCity,
      latitude: latitude,
      longitude: longitude,
      victim: victim,
      tags: tags,
      timeline: timeline,
      links: links,
      photos: photos,
      chapters: chapters,
    );
  }

  factory CaseDraft.fromJson(Map<String, dynamic> json) {
    return CaseDraft(
      draftId: json['draftId'] as String,
      title: json['title'] as String?,
      category: json['category'] == null
          ? null
          : CaseCategory.fromJson(json['category'] as String),
      year: json['year'] as int?,
      status: json['status'] == null
          ? null
          : CaseStatus.fromJson(json['status'] as String),
      summary: json['summary'] as String?,
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
      regionOrCity: json['regionOrCity'] as String?,
      // `num` y no `double`: jsonDecode devuelve int para una coordenada
      // entera como 40.
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      victim: json['victim'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .map(
            (event) =>
                DraftTimelineEvent.fromJson(event as Map<String, dynamic>),
          )
          .toList(growable: false),
      links: (json['links'] as List<dynamic>? ?? const [])
          .map((link) => DraftLink.fromJson(link as Map<String, dynamic>))
          .toList(growable: false),
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((photo) => DraftPhoto.fromJson(photo as Map<String, dynamic>))
          .toList(growable: false),
      chapters: CaseChapters.fromJson(json['chapters']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draftId': draftId,
      if (title != null) 'title': title,
      if (category != null) 'category': category!.name,
      if (year != null) 'year': year,
      if (status != null) 'status': status!.name,
      if (summary != null) 'summary': summary,
      if (country != null) 'country': country,
      if (countryCode != null) 'countryCode': countryCode,
      if (regionOrCity != null) 'regionOrCity': regionOrCity,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (victim != null) 'victim': victim,
      'tags': tags,
      'timeline': timeline.map((event) => event.toJson()).toList(),
      'links': links.map((link) => link.toJson()).toList(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      // Se omite entero cuando no hay nada significativo, para que un borrador
      // sin capítulos sea byte a byte como antes de que existieran.
      if (chapters.orderedMeaningful.isNotEmpty) 'chapters': chapters.toJson(),
    };
  }
}

/// Convierte la línea que se escribe en el formulario en la lista de tags.
///
/// Los normaliza a minúsculas y sin repetidos para que casen con el catálogo
/// publicado, donde los tags son cortos y en minúscula ("1960s", "ee. uu.").
List<String> parseTags(String line) {
  final tags = <String>[];
  for (final piece in line.split(',')) {
    final tag = piece.trim().toLowerCase();
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
    }
  }
  return List.unmodifiable(tags);
}

/// Devuelve los tags a la línea editable del formulario.
String formatTags(List<String> tags) => tags.join(', ');

/// Hito de la cronología del borrador.
///
/// Reutiliza [CaseTimelineKind] del caso publicado porque los tipos son los
/// mismos; el tipo queda opcional mientras el hito se está redactando.
class DraftTimelineEvent {
  const DraftTimelineEvent({this.date, this.title, this.kind});

  final String? date;
  final String? title;
  final CaseTimelineKind? kind;

  factory DraftTimelineEvent.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    return DraftTimelineEvent(
      date: json['date'] as String?,
      title: json['title'] as String?,
      // Tolerante: un tipo desconocido no debe dejar el borrador inaccesible.
      kind: kind is String ? CaseTimelineKind.tryFromJson(kind) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (date != null) 'date': date,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind!.name,
    };
  }
}

/// Fotografía del borrador: URL de una imagen ya alojada más un pie opcional.
/// v1 no sube archivos; la subida real queda diferida (IndexedDB/base64).
class DraftPhoto {
  const DraftPhoto({this.url, this.caption});

  final String? url;
  final String? caption;

  factory DraftPhoto.fromJson(Map<String, dynamic> json) {
    return DraftPhoto(
      url: json['url'] as String?,
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (url != null) 'url': url,
      if (caption != null) 'caption': caption,
    };
  }
}

/// Tipo de enlace externo del borrador. Tolerante con los borradores de la
/// fase 2, que guardaban `kind` como texto libre: cualquier valor
/// desconocido o ausente se degrada a [DraftLinkKind.other] sin romper la carga.
enum DraftLinkKind {
  podcast,
  video,
  document,
  publication,
  other;

  factory DraftLinkKind.fromJson(String value) {
    return switch (value) {
      'podcast' => DraftLinkKind.podcast,
      'video' => DraftLinkKind.video,
      'document' => DraftLinkKind.document,
      'publication' => DraftLinkKind.publication,
      _ => DraftLinkKind.other,
    };
  }

  String get label {
    return switch (this) {
      DraftLinkKind.podcast => 'Podcast',
      DraftLinkKind.video => 'Vídeo',
      DraftLinkKind.document => 'Documento',
      DraftLinkKind.publication => 'Publicación',
      DraftLinkKind.other => 'Otro',
    };
  }
}

/// Enlace externo capturado en el borrador (fuente, podcast, artículo…).
class DraftLink {
  const DraftLink({this.title, this.url, this.kind});

  final String? title;
  final String? url;
  final DraftLinkKind? kind;

  factory DraftLink.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    return DraftLink(
      title: json['title'] as String?,
      url: json['url'] as String?,
      kind: kind is String ? DraftLinkKind.fromJson(kind) : DraftLinkKind.other,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (kind != null) 'kind': kind!.name,
    };
  }
}
