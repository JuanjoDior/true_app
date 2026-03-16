import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/true_crime_case.dart';
import 'cases_repository.dart';

class LocalCasesRepository implements CasesRepository {
  LocalCasesRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/cases.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  @override
  Future<List<TrueCrimeCase>> getCases() async {
    final payload = await _bundle.loadString(assetPath);
    return parseCasesJson(payload);
  }

  static List<TrueCrimeCase> parseCasesJson(String payload) {
    final decoded = jsonDecode(payload) as List<dynamic>;
    return decoded
        .map((item) => TrueCrimeCase.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
