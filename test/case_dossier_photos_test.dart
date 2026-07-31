import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_photo.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_panel.dart';

import 'test_support/sample_cases.dart';

TrueCrimeCase caseWithPhotos(List<CasePhoto> photos) {
  return TrueCrimeCase(
    id: 'caso-faro',
    slug: 'caso-faro',
    title: 'El caso del faro',
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'A Coruña',
    year: 1974,
    latitude: 43.39,
    longitude: -8.41,
    summary: 'Resumen del caso.',
    tags: const <String>[],
    sources: const [],
    photos: photos,
  );
}

Future<void> _pumpDossier(WidgetTester tester, TrueCrimeCase crimeCase) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 900, child: CaseDossierPanel(crimeCase: crimeCase)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders the photos of a published case with their captions',
      (tester) async {
    await _pumpDossier(
      tester,
      caseWithPhotos(const [
        CasePhoto(url: 'https://example.com/faro.jpg', caption: 'El faro'),
        CasePhoto(url: 'https://example.com/plano.png'),
      ]),
    );

    expect(find.byKey(const Key('case-photos')), findsOneWidget);
    expect(find.byKey(const Key('case-photo-0')), findsOneWidget);
    expect(find.byKey(const Key('case-photo-1')), findsOneWidget);
    expect(find.text('El faro'), findsOneWidget);
  });

  testWidgets('hides the photo section when the case has none', (tester) async {
    await _pumpDossier(tester, caseWithPhotos(const []));

    expect(find.byKey(const Key('case-photos')), findsNothing);
  });

  testWidgets('falls back to a placeholder when an image cannot load',
      (tester) async {
    // En test toda petición de red falla, así que este es el camino del
    // errorBuilder: la ficha se sigue pintando entera.
    await _pumpDossier(
      tester,
      caseWithPhotos(const [CasePhoto(url: 'https://example.com/rota.jpg')]),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('case-photos')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
