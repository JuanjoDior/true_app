import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

const sampleCases = <TrueCrimeCase>[
  TrueCrimeCase(
    id: 'zodiac-killer',
    slug: 'zodiac-killer',
    title: 'Zodiac Killer',
    category: CaseCategory.serialKiller,
    country: 'United States',
    countryCode: 'US',
    regionOrCity: 'San Francisco',
    year: 1968,
    latitude: 37.7749,
    longitude: -122.4194,
    summary:
        'Un asesino sin identificar que desafió a la prensa y a la policía.',
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
    id: 'meredith-kercher',
    slug: 'meredith-kercher',
    title: 'Meredith Kercher',
    category: CaseCategory.isolatedMurder,
    country: 'Italy',
    countryCode: 'IT',
    regionOrCity: 'Perugia',
    year: 2007,
    latitude: 43.1107,
    longitude: 12.3908,
    summary:
        'Un homicidio aislado con enorme repercusión judicial y mediática.',
    tags: ['italy', 'trial', 'media frenzy'],
    featuredRank: 2,
    relevanceRank: 4,
    sources: [
      CaseSource(
        id: 'kercher-investigation',
        title: 'Wikipedia: Murder of Meredith Kercher',
        url: 'https://en.wikipedia.org/wiki/Murder_of_Meredith_Kercher',
        kind: CaseSourceKind.investigation,
      ),
      CaseSource(
        id: 'kercher-podcast',
        title: 'Spotify: Meredith Kercher podcast search',
        url:
            'https://open.spotify.com/search/Meredith%20Kercher%20podcast/episodes',
        kind: CaseSourceKind.podcast,
      ),
    ],
  ),
  TrueCrimeCase(
    id: 'madeleine-mccann',
    slug: 'madeleine-mccann',
    title: 'Madeleine McCann',
    category: CaseCategory.kidnapping,
    country: 'Portugal',
    countryCode: 'PT',
    regionOrCity: 'Praia da Luz',
    year: 2007,
    latitude: 37.0889,
    longitude: -8.7284,
    summary:
        'Una desaparición de alcance internacional con investigación abierta.',
    tags: ['missing person', 'international', 'portugal'],
    featuredRank: 3,
    relevanceRank: 1,
    sources: [
      CaseSource(
        id: 'madeleine-investigation',
        title: 'Wikipedia: Disappearance of Madeleine McCann',
        url: 'https://en.wikipedia.org/wiki/Disappearance_of_Madeleine_McCann',
        kind: CaseSourceKind.investigation,
      ),
      CaseSource(
        id: 'madeleine-podcast',
        title: 'Spotify: Madeleine McCann podcast search',
        url:
            'https://open.spotify.com/search/Madeleine%20McCann%20podcast/episodes',
        kind: CaseSourceKind.podcast,
      ),
    ],
  ),
  TrueCrimeCase(
    id: 'black-dahlia',
    slug: 'black-dahlia',
    title: 'Black Dahlia',
    category: CaseCategory.unsolved,
    country: 'United States',
    countryCode: 'US',
    regionOrCity: 'Los Angeles',
    year: 1947,
    latitude: 34.0522,
    longitude: -118.2437,
    summary: 'Uno de los expedientes sin resolver más icónicos del siglo XX.',
    tags: ['unsolved', 'hollywood', 'cold case'],
    featuredRank: 4,
    relevanceRank: 3,
    sources: [
      CaseSource(
        id: 'dahlia-investigation',
        title: 'Wikipedia: Black Dahlia',
        url: 'https://en.wikipedia.org/wiki/Black_Dahlia',
        kind: CaseSourceKind.investigation,
      ),
      CaseSource(
        id: 'dahlia-podcast',
        title: 'Spotify: Black Dahlia podcast search',
        url:
            'https://open.spotify.com/search/Black%20Dahlia%20podcast/episodes',
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
