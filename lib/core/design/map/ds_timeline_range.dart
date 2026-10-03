abstract final class DsTimelineRange {
  static const int startYear = 1888;
  static const int endYear = 2025;

  static const int _span = endYear - startYear;

  static double markPosition(int year) =>
      ((year - startYear) / _span).clamp(0.0, 1.0);
}
