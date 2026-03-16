import '../domain/true_crime_case.dart';

class CaseSearchService {
  const CaseSearchService();

  List<TrueCrimeCase> topFeatured(List<TrueCrimeCase> cases, {int limit = 8}) {
    final sorted = [...cases]
      ..sort((left, right) => left.featuredRank.compareTo(right.featuredRank));
    return sorted.take(limit).toList(growable: false);
  }

  List<TrueCrimeCase> topRelevant(List<TrueCrimeCase> cases, {int limit = 6}) {
    final sorted = [
      ...cases,
    ]..sort((left, right) => left.relevanceRank.compareTo(right.relevanceRank));
    return sorted.take(limit).toList(growable: false);
  }

  List<TrueCrimeCase> search(List<TrueCrimeCase> cases, String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      final sorted = [...cases]
        ..sort(
          (left, right) => left.relevanceRank.compareTo(right.relevanceRank),
        );
      return sorted;
    }

    final matches = cases
        .where((crimeCase) {
          final searchableText = [
            crimeCase.title,
            crimeCase.country,
            crimeCase.regionOrCity,
            ...crimeCase.tags,
          ].map(_normalize).join(' ');

          return searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);

    matches.sort((left, right) {
      final leftScore = _score(left, normalizedQuery);
      final rightScore = _score(right, normalizedQuery);
      if (leftScore != rightScore) {
        return rightScore.compareTo(leftScore);
      }
      return left.relevanceRank.compareTo(right.relevanceRank);
    });

    return matches;
  }

  int _score(TrueCrimeCase crimeCase, String query) {
    final normalizedTitle = _normalize(crimeCase.title);
    final normalizedCountry = _normalize(crimeCase.country);
    final normalizedRegion = _normalize(crimeCase.regionOrCity);
    final normalizedTags = crimeCase.tags.map(_normalize);

    if (normalizedTitle == query) {
      return 4;
    }
    if (normalizedTitle.startsWith(query)) {
      return 3;
    }
    if (normalizedRegion.contains(query) || normalizedCountry.contains(query)) {
      return 2;
    }
    if (normalizedTags.any((tag) => tag.contains(query))) {
      return 1;
    }
    return 0;
  }

  String _normalize(String value) {
    const replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'à': 'a',
      'è': 'e',
      'ì': 'i',
      'ò': 'o',
      'ù': 'u',
      'ä': 'a',
      'ë': 'e',
      'ï': 'i',
      'ö': 'o',
      'ü': 'u',
      'â': 'a',
      'ê': 'e',
      'î': 'i',
      'ô': 'o',
      'û': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    final lowered = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lowered.runes) {
      final character = String.fromCharCode(rune);
      buffer.write(replacements[character] ?? character);
    }
    return buffer.toString();
  }
}
