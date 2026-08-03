import '../domain/true_crime_case.dart';

class CaseSearchService {
  const CaseSearchService();

  List<TrueCrimeCase> search(List<TrueCrimeCase> cases, String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      final sorted = [...cases]..sort(_compareByRelevance);
      return sorted;
    }

    final matches = cases
        .where((crimeCase) {
          final searchableText = [
            crimeCase.title,
            crimeCase.country,
            crimeCase.regionOrCity,
            crimeCase.category.label,
            crimeCase.category.shortLabel,
            ...crimeCase.category.searchTerms,
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
      return _compareByRelevance(left, right);
    });

    return matches;
  }

  int _score(TrueCrimeCase crimeCase, String query) {
    final normalizedTitle = _normalize(crimeCase.title);
    final normalizedCountry = _normalize(crimeCase.country);
    final normalizedRegion = _normalize(crimeCase.regionOrCity);
    final normalizedCategory = _normalize(crimeCase.category.label);
    final normalizedShortCategory = _normalize(crimeCase.category.shortLabel);
    final normalizedTags = crimeCase.tags.map(_normalize);
    final normalizedCategoryTerms = crimeCase.category.searchTerms.map(
      _normalize,
    );

    if (normalizedTitle == query) {
      return 5;
    }
    if (normalizedTitle.startsWith(query)) {
      return 4;
    }
    if (normalizedCategory == query || normalizedShortCategory == query) {
      return 3;
    }
    if (normalizedRegion.contains(query) || normalizedCountry.contains(query)) {
      return 2;
    }
    if (normalizedTags.any((tag) => tag.contains(query)) ||
        normalizedCategoryTerms.any((term) => term.contains(query))) {
      return 1;
    }
    return 0;
  }

  int _compareByRelevance(TrueCrimeCase left, TrueCrimeCase right) {
    final leftRank = left.relevanceRank ?? 1 << 20;
    final rightRank = right.relevanceRank ?? 1 << 20;

    if (leftRank != rightRank) {
      return leftRank.compareTo(rightRank);
    }

    return left.title.compareTo(right.title);
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
