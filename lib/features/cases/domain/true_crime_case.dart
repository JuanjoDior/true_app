import 'package:latlong2/latlong.dart';

import 'case_source.dart';

class TrueCrimeCase {
  const TrueCrimeCase({
    required this.id,
    required this.slug,
    required this.title,
    required this.country,
    required this.countryCode,
    required this.regionOrCity,
    required this.year,
    required this.latitude,
    required this.longitude,
    required this.summary,
    required this.tags,
    required this.featuredRank,
    required this.relevanceRank,
    required this.sources,
  });

  final String id;
  final String slug;
  final String title;
  final String country;
  final String countryCode;
  final String regionOrCity;
  final int year;
  final double latitude;
  final double longitude;
  final String summary;
  final List<String> tags;
  final int featuredRank;
  final int relevanceRank;
  final List<CaseSource> sources;

  LatLng get location => LatLng(latitude, longitude);

  String get locationLabel => '$regionOrCity, $country';

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
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
      regionOrCity: json['regionOrCity'] as String,
      year: json['year'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      summary: json['summary'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      featuredRank: json['featuredRank'] as int,
      relevanceRank: json['relevanceRank'] as int,
      sources: (json['sources'] as List<dynamic>)
          .map((source) => CaseSource.fromJson(source as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
