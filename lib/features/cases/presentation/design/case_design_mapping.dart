import 'dart:ui' show Color;

import '../../../../core/design/design.dart';
import '../../domain/case_category.dart';
import '../../domain/case_status.dart';
import '../../domain/true_crime_case.dart';

extension CaseCategoryDesign on CaseCategory {
  DsCategoryColor get designColor {
    return switch (this) {
      CaseCategory.serialKiller => DsCategoryColors.serialKiller,
      CaseCategory.isolatedMurder => DsCategoryColors.isolatedMurder,
      CaseCategory.kidnapping => DsCategoryColors.kidnapping,
      CaseCategory.unsolved => DsCategoryColors.unsolved,
    };
  }
}

extension CaseStatusDesign on CaseStatus {
  Color get designColor {
    return switch (this) {
      CaseStatus.open => DsStatusColors.open,
      CaseStatus.solved => DsStatusColors.solved,
      CaseStatus.inProgress => DsStatusColors.inProgress,
    };
  }
}

extension TrueCrimeCaseDesign on TrueCrimeCase {
  DsMapMarker toMapMarker() {
    return DsMapMarker(
      id: id,
      label: title,
      latitude: latitude,
      longitude: longitude,
      color: category.designColor.dot,
      year: year,
    );
  }
}
