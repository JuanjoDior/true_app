import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/case_status.dart';
import '../domain/case_timeline_event.dart';

/// Color editorial de cada estado de investigación.
extension CaseStatusPresentation on CaseStatus {
  Color get color {
    return switch (this) {
      CaseStatus.open => AppColors.statusOpen,
      CaseStatus.solved => AppColors.statusSolved,
      CaseStatus.inProgress => AppColors.statusProgress,
    };
  }
}

/// Color de cada hito de la cronología verificada.
extension CaseTimelineKindPresentation on CaseTimelineKind {
  Color get color {
    return switch (this) {
      CaseTimelineKind.initial => AppColors.accent,
      CaseTimelineKind.process => AppColors.catIsolated,
      CaseTimelineKind.open => AppColors.statusOpen,
      CaseTimelineKind.solved => AppColors.statusSolved,
    };
  }
}
