import 'case_category.dart';
import 'case_status.dart';

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
    this.links = const <DraftLink>[],
    this.photos = const <DraftPhoto>[],
  });

  /// Identidad local estable del borrador, independiente del título.
  final String draftId;
  final String? title;
  final CaseCategory? category;
  final int? year;
  final CaseStatus? status;
  final String? summary;
  final List<DraftLink> links;

  /// Fotografías del caso: sólo URLs ya alojadas, sin subida de archivos
  /// (política "sin backend, sin CMS") [Diseño #14].
  final List<DraftPhoto> photos;

  CaseDraft copyWith({
    String? title,
    CaseCategory? category,
    int? year,
    CaseStatus? status,
    String? summary,
    List<DraftLink>? links,
    List<DraftPhoto>? photos,
  }) {
    return CaseDraft(
      draftId: draftId,
      title: title ?? this.title,
      category: category ?? this.category,
      year: year ?? this.year,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      links: links ?? this.links,
      photos: photos ?? this.photos,
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
      links: (json['links'] as List<dynamic>? ?? const [])
          .map((link) => DraftLink.fromJson(link as Map<String, dynamic>))
          .toList(growable: false),
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((photo) => DraftPhoto.fromJson(photo as Map<String, dynamic>))
          .toList(growable: false),
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
      'links': links.map((link) => link.toJson()).toList(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
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
      kind: kind is String
          ? DraftLinkKind.fromJson(kind)
          : DraftLinkKind.other,
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
