import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/design/case_design_mapping.dart';

void main() {
  group('CaseCategory.designColor', () {
    test('maps each category to its same-named design constant', () {
      expect(
        CaseCategory.serialKiller.designColor,
        same(DsCategoryColors.serialKiller),
      );
      expect(
        CaseCategory.isolatedMurder.designColor,
        same(DsCategoryColors.isolatedMurder),
      );
      expect(
        CaseCategory.kidnapping.designColor,
        same(DsCategoryColors.kidnapping),
      );
      expect(
        CaseCategory.unsolved.designColor,
        same(DsCategoryColors.unsolved),
      );
    });

    test('covers every enum value with a distinct dot colour', () {
      final dots = {for (final c in CaseCategory.values) c.designColor.dot};
      expect(dots, hasLength(CaseCategory.values.length));
    });
  });

  group('CaseStatus.designColor', () {
    test('maps each status to its design status colour', () {
      expect(CaseStatus.open.designColor, DsStatusColors.open);
      expect(CaseStatus.solved.designColor, DsStatusColors.solved);
      expect(CaseStatus.inProgress.designColor, DsStatusColors.inProgress);
    });

    test('covers every enum value with a distinct colour', () {
      final colors = {for (final s in CaseStatus.values) s.designColor};
      expect(colors, hasLength(CaseStatus.values.length));
    });
  });

  group('TrueCrimeCase.toMapMarker', () {
    const crimeCase = TrueCrimeCase(
      id: 'case-1',
      slug: 'case-1-slug',
      title: 'Caso Uno',
      category: CaseCategory.kidnapping,
      country: 'España',
      countryCode: 'ES',
      regionOrCity: 'Madrid',
      year: 1993,
      latitude: 40.4168,
      longitude: -3.7038,
      summary: 'Resumen.',
      tags: [],
      sources: [],
    );

    test('carries id, title, coordinates, year and category dot colour', () {
      expect(
        crimeCase.toMapMarker(),
        DsMapMarker(
          id: 'case-1',
          label: 'Caso Uno',
          latitude: 40.4168,
          longitude: -3.7038,
          color: DsCategoryColors.kidnapping.dot,
          year: 1993,
        ),
      );
    });

    test('uses the marker id (not the slug) as identity', () {
      expect(crimeCase.toMapMarker().id, 'case-1');
    });
  });
}
