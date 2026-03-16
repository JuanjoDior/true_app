enum CaseSourceKind {
  investigation,
  podcast;

  factory CaseSourceKind.fromJson(String value) {
    return switch (value) {
      'investigation' => CaseSourceKind.investigation,
      'podcast' => CaseSourceKind.podcast,
      _ => throw ArgumentError.value(value, 'value', 'Unknown source kind'),
    };
  }

  String get label {
    return switch (this) {
      CaseSourceKind.investigation => 'Investigación',
      CaseSourceKind.podcast => 'Podcast',
    };
  }
}

class CaseSource {
  const CaseSource({
    required this.id,
    required this.title,
    required this.url,
    required this.kind,
  });

  final String id;
  final String title;
  final String url;
  final CaseSourceKind kind;

  factory CaseSource.fromJson(Map<String, dynamic> json) {
    return CaseSource(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      kind: CaseSourceKind.fromJson(json['kind'] as String),
    );
  }
}
