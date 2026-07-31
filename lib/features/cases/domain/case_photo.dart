/// Fotografía de un caso publicado: una imagen ya alojada más un pie
/// opcional. El catálogo no sube archivos (política "sin backend, sin CMS"),
/// así que sólo guarda la URL de origen.
class CasePhoto {
  const CasePhoto({required this.url, this.caption});

  final String url;
  final String? caption;

  /// Devuelve `null` cuando la entrada no tiene una URL usable: una foto sin
  /// imagen no se puede pintar y no debe llegar a la vista.
  static CasePhoto? tryFromJson(Map<String, dynamic> json) {
    final url = (json['url'] as String?)?.trim() ?? '';
    if (url.isEmpty) {
      return null;
    }
    final caption = (json['caption'] as String?)?.trim();
    return CasePhoto(
      url: url,
      caption: caption?.isNotEmpty ?? false ? caption : null,
    );
  }
}
