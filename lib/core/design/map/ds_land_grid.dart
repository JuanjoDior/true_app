import '../tokens/ds_colors.dart';

/// fila -> rangos [col inicial, col final] con tierra. 5º por celda.
const _kLandMask = <int, List<List<int>>>{
  0: [
    [21, 32],
    [39, 40],
    [55, 56],
  ],
  1: [
    [9, 19],
    [21, 33],
    [49, 50],
    [54, 71],
  ],
  2: [
    [2, 22],
    [23, 31],
    [37, 71],
  ],
  3: [
    [2, 16],
    [20, 24],
    [26, 28],
    [31, 32],
    [37, 71],
  ],
  4: [
    [3, 16],
    [21, 24],
    [35, 35],
    [38, 71],
  ],
  5: [
    [4, 16],
    [20, 25],
    [34, 35],
    [36, 71],
  ],
  6: [
    [5, 25],
    [35, 71],
  ],
  7: [
    [10, 25],
    [34, 40],
    [45, 64],
  ],
  8: [
    [11, 24],
    [34, 37],
    [38, 38],
    [41, 64],
  ],
  9: [
    [12, 23],
    [34, 63],
  ],
  10: [
    [13, 20],
    [33, 63],
  ],
  11: [
    [12, 18],
    [20, 21],
    [33, 49],
    [50, 62],
  ],
  12: [
    [16, 19],
    [21, 23],
    [33, 47],
    [45, 48],
    [50, 53],
    [55, 58],
    [60, 60],
  ],
  13: [
    [17, 19],
    [20, 24],
    [33, 46],
    [47, 47],
    [51, 52],
    [55, 57],
    [60, 60],
  ],
  14: [
    [18, 19],
    [20, 26],
    [33, 47],
    [52, 52],
    [55, 56],
    [57, 59],
  ],
  15: [
    [20, 29],
    [36, 46],
    [55, 56],
    [57, 59],
    [60, 61],
    [63, 65],
  ],
  16: [
    [20, 29],
    [36, 45],
    [55, 56],
    [57, 59],
    [62, 66],
  ],
  17: [
    [20, 30],
    [37, 44],
    [56, 58],
    [63, 66],
  ],
  18: [
    [21, 30],
    [37, 44],
    [57, 60],
    [62, 64],
  ],
  19: [
    [22, 30],
    [38, 45],
    [59, 66],
  ],
  20: [
    [22, 28],
    [38, 45],
    [58, 66],
  ],
  21: [
    [22, 28],
    [38, 43],
    [58, 66],
  ],
  22: [
    [22, 27],
    [39, 43],
    [59, 66],
  ],
  23: [
    [22, 26],
    [60, 66],
    [69, 70],
  ],
  24: [
    [22, 26],
    [65, 65],
    [69, 70],
  ],
  25: [
    [22, 25],
    [69, 70],
  ],
  26: [
    [22, 25],
  ],
};

class DsLandCell {
  const DsLandCell({
    required this.col,
    required this.row,
    required this.longitude,
    required this.latitude,
    required this.opacity,
  });

  final int col;
  final int row;
  final double longitude;
  final double latitude;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is DsLandCell &&
      other.col == col &&
      other.row == row &&
      other.longitude == longitude &&
      other.latitude == latitude &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(col, row, longitude, latitude, opacity);
}

abstract final class DsLandGrid {
  static const int columns = 72;
  static const int rows = 27;
  static const int cellDegrees = 5;
  static const int firstLatitude = 80;
  static const int firstLongitude = -180;

  static const Map<int, List<List<int>>> mask = _kLandMask;

  static bool isLand(int col, int row) {
    final ranges = mask[row];
    if (ranges == null) return false;
    for (final range in ranges) {
      if (col >= range[0] && col <= range[1]) return true;
    }
    return false;
  }

  static double centerLongitude(int col) =>
      firstLongitude + cellDegrees * col + cellDegrees / 2;

  static double centerLatitude(int row) =>
      firstLatitude - cellDegrees * row - cellDegrees / 2;

  static double dotOpacity(int col, int row) =>
      DsColors.landDotOpacity(col, row);

  static final List<DsLandCell> cells = _buildCells();

  // Los rangos de una fila pueden solaparse: un Set evita celdas duplicadas.
  static List<DsLandCell> _buildCells() {
    final result = <DsLandCell>[];
    for (var row = 0; row < rows; row++) {
      final landCols = <int>{};
      for (final range in mask[row] ?? const <List<int>>[]) {
        for (var col = range[0]; col <= range[1]; col++) {
          landCols.add(col);
        }
      }
      for (final col in landCols.toList()..sort()) {
        result.add(
          DsLandCell(
            col: col,
            row: row,
            longitude: centerLongitude(col),
            latitude: centerLatitude(row),
            opacity: dotOpacity(col, row),
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }
}
