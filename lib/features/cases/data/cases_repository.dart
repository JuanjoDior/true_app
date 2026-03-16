import '../domain/true_crime_case.dart';

abstract class CasesRepository {
  Future<List<TrueCrimeCase>> getCases();
}
