import 'package:latlong2/latlong.dart';

import 'case_category.dart';
import 'case_photo.dart';
import 'case_source.dart';
import 'case_status.dart';
import 'case_timeline_event.dart';

class TrueCrimeCase {
  const TrueCrimeCase({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.country,
    required this.countryCode,
    required this.regionOrCity,
    required this.year,
    required this.latitude,
    required this.longitude,
    required this.summary,
    required this.tags,
    this.featuredRank,
    this.relevanceRank,
    required this.sources,
    this.status = CaseStatus.open,
    this.statusLabel,
    this.victim,
    this.timeline = const <CaseTimelineEvent>[],
    this.photos = const <CasePhoto>[],
  });

  final String id;
  final String slug;
  final String title;
  final CaseCategory category;
  final String country;
  final String countryCode;
  final String regionOrCity;
  final int year;
  final double latitude;
  final double longitude;
  final String summary;
  final List<String> tags;
  final int? featuredRank;
  final int? relevanceRank;
  final List<CaseSource> sources;

  /// Estado de investigación (abierto, resuelto, en curso).
  final CaseStatus status;

  /// Texto editorial del estado, p. ej. "Resuelto (2018)" o "Reabierto (2019)".
  final String? statusLabel;

  /// Descripción de la víctima o víctimas, nombrada con respeto.
  final String? victim;

  /// Cronología verificada del caso.
  final List<CaseTimelineEvent> timeline;

  /// Fotografías del caso, alojadas fuera y referenciadas por URL.
  final List<CasePhoto> photos;

  LatLng get location => LatLng(latitude, longitude);

  String get locationLabel => '$regionOrCity, $country';

  /// Coordenadas con el formato editorial del archivo: "37.77° N · 122.42° O".
  String get coordsLabel {
    final lat = latitude.abs().toStringAsFixed(2);
    final lng = longitude.abs().toStringAsFixed(2);
    final latHemisphere = latitude >= 0 ? 'N' : 'S';
    final lngHemisphere = longitude >= 0 ? 'E' : 'O';
    return '$lat° $latHemisphere · $lng° $lngHemisphere';
  }

  List<CaseSource> get investigationSources {
    return sources
        .where((source) => source.kind == CaseSourceKind.investigation)
        .toList(growable: false);
  }

  List<CaseSource> get podcastSources {
    return sources
        .where((source) => source.kind == CaseSourceKind.podcast)
        .toList(growable: false);
  }

  factory TrueCrimeCase.fromJson(Map<String, dynamic> json) {
    return TrueCrimeCase(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      category: CaseCategory.fromJson(json['category'] as String),
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
      regionOrCity: json['regionOrCity'] as String,
      year: json['year'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      summary: json['summary'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      featuredRank: json['featuredRank'] as int?,
      relevanceRank: json['relevanceRank'] as int?,
      sources: (json['sources'] as List<dynamic>)
          .map((source) => CaseSource.fromJson(source as Map<String, dynamic>))
          .toList(growable: false),
      status: json['status'] == null
          ? CaseStatus.open
          : CaseStatus.fromJson(json['status'] as String),
      statusLabel: json['statusLabel'] as String?,
      victim: json['victim'] as String?,
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .map((event) =>
              CaseTimelineEvent.fromJson(event as Map<String, dynamic>))
          .toList(growable: false),
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((photo) => CasePhoto.tryFromJson(photo as Map<String, dynamic>))
          .nonNulls
          .toList(growable: false),
    );
  }
}
