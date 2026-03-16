import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

const sampleCases = <TrueCrimeCase>[
  TrueCrimeCase(
    id: 'zodiac-killer',
    slug: 'zodiac-killer',
    title: 'Zodiac Killer',
    country: 'United States',
    countryCode: 'US',
    regionOrCity: 'San Francisco',
    year: 1968,
    latitude: 37.7749,
    longitude: -122.4194,
    summary:
        'Un asesino sin identificar que desafio a la prensa y a la policia.',
    tags: ['serial killer', 'cipher', 'unsolved'],
    featuredRank: 1,
    relevanceRank: 2,
    sources: [
      CaseSource(
        id: 'zodiac-investigation',
        title: 'Wikipedia: Zodiac Killer',
        url: 'https://en.wikipedia.org/wiki/Zodiac_Killer',
        kind: CaseSourceKind.investigation,
      ),
      CaseSource(
        id: 'zodiac-podcast',
        title: 'Spotify: Zodiac Killer podcast search',
        url:
            'https://open.spotify.com/search/Zodiac%20Killer%20podcast/episodes',
        kind: CaseSourceKind.podcast,
      ),
    ],
  ),
  TrueCrimeCase(
    id: 'alcasser-girls',
    slug: 'alcasser-girls',
    title: 'Alcasser Girls',
    country: 'Spain',
    countryCode: 'ES',
    regionOrCity: 'Alcasser',
    year: 1992,
    latitude: 39.3691,
    longitude: -0.4426,
    summary: 'Uno de los casos mas recordados del crimen televisado en Espana.',
    tags: ['spain', 'media frenzy', 'cold case'],
    featuredRank: 2,
    relevanceRank: 1,
    sources: [
      CaseSource(
        id: 'alcasser-investigation',
        title: 'Wikipedia: Alcasser Girls',
        url: 'https://en.wikipedia.org/wiki/Alc%C3%A0sser_Girls',
        kind: CaseSourceKind.investigation,
      ),
      CaseSource(
        id: 'alcasser-podcast',
        title: 'Spotify: Alcasser podcast search',
        url: 'https://open.spotify.com/search/Alcasser%20podcast/episodes',
        kind: CaseSourceKind.podcast,
      ),
    ],
  ),
  TrueCrimeCase(
    id: 'manson-family-murders',
    slug: 'manson-family-murders',
    title: 'Manson Family murders',
    country: 'United States',
    countryCode: 'US',
    regionOrCity: 'Los Angeles',
    year: 1969,
    latitude: 34.0983,
    longitude: -118.3267,
    summary: 'Un crimen de culto con enorme impacto cultural.',
    tags: ['cult', 'hollywood', 'serial violence'],
    featuredRank: 3,
    relevanceRank: 3,
    sources: [
      CaseSource(
        id: 'manson-investigation',
        title: 'Wikipedia: Tate-LaBianca murders',
        url: 'https://en.wikipedia.org/wiki/Tate%E2%80%93LaBianca_murders',
        kind: CaseSourceKind.investigation,
      ),
      CaseSource(
        id: 'manson-podcast',
        title: 'Spotify: Manson Family podcast search',
        url:
            'https://open.spotify.com/search/Manson%20Family%20podcast/episodes',
        kind: CaseSourceKind.podcast,
      ),
    ],
  ),
];

class FakeCasesRepository implements CasesRepository {
  const FakeCasesRepository(this.cases);

  final List<TrueCrimeCase> cases;

  @override
  Future<List<TrueCrimeCase>> getCases() async => cases;
}
