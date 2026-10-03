import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

// Copia literal de la tabla del documento (docs/design/map-and-globe.md, 1).
const _docMask = <int, List<List<int>>>{
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

Set<(int, int)> _expandedLand() {
  final land = <(int, int)>{};
  _docMask.forEach((row, ranges) {
    for (final range in ranges) {
      for (var col = range[0]; col <= range[1]; col++) {
        land.add((col, row));
      }
    }
  });
  return land;
}

void main() {
  group('DsLandGrid', () {
    test('dimensions', () {
      expect(DsLandGrid.columns, 72);
      expect(DsLandGrid.rows, 27);
      expect(DsLandGrid.cellDegrees, 5);
      expect(DsLandGrid.firstLatitude, 80);
      expect(DsLandGrid.firstLongitude, -180);
    });

    test('cell centers', () {
      expect(DsLandGrid.centerLongitude(0), -177.5);
      expect(DsLandGrid.centerLatitude(0), 77.5);
      expect(DsLandGrid.centerLongitude(71), 177.5);
      expect(DsLandGrid.centerLatitude(26), -52.5);
    });

    test('mask is exactly the design doc table', () {
      expect(DsLandGrid.mask.keys.toList()..sort(), [
        for (var row = 0; row < 27; row++) row,
      ]);
      expect(DsLandGrid.mask, _docMask);
      for (final row in [0, 6, 12, 13, 23, 26]) {
        expect(DsLandGrid.mask[row], _docMask[row], reason: 'row $row');
      }
    });

    test('every range stays inside the grid and is ordered', () {
      DsLandGrid.mask.forEach((row, ranges) {
        expect(row, inInclusiveRange(0, DsLandGrid.rows - 1));
        for (final range in ranges) {
          expect(range, hasLength(2), reason: 'row $row');
          expect(range[0], inInclusiveRange(0, DsLandGrid.columns - 1));
          expect(range[1], inInclusiveRange(0, DsLandGrid.columns - 1));
          expect(range[0], lessThanOrEqualTo(range[1]), reason: 'row $row');
        }
      });
    });

    test('isLand answers land and water cells', () {
      expect(DsLandGrid.isLand(21, 0), isTrue);
      expect(DsLandGrid.isLand(20, 0), isFalse);
      expect(DsLandGrid.isLand(33, 0), isFalse);
      expect(DsLandGrid.isLand(22, 26), isTrue);
      expect(DsLandGrid.isLand(26, 26), isFalse);
    });

    test('isLand agrees with the expanded doc table on every cell', () {
      final land = _expandedLand();
      for (var row = 0; row < DsLandGrid.rows; row++) {
        for (var col = 0; col < DsLandGrid.columns; col++) {
          expect(
            DsLandGrid.isLand(col, row),
            land.contains((col, row)),
            reason: 'col $col row $row',
          );
        }
      }
    });

    test('cells has no duplicates and matches the independent count', () {
      final cells = DsLandGrid.cells;
      final keys = cells.map((c) => (c.col, c.row)).toSet();
      expect(keys.length, cells.length);
      expect(cells.length, _expandedLand().length);
      expect(keys, _expandedLand());
    });

    test('cells are ordered by row then column', () {
      final cells = DsLandGrid.cells;
      for (var i = 1; i < cells.length; i++) {
        final a = cells[i - 1];
        final b = cells[i];
        expect(
          a.row < b.row || (a.row == b.row && a.col < b.col),
          isTrue,
          reason: 'index $i',
        );
      }
    });

    test('cells are immutable', () {
      expect(
        () => DsLandGrid.cells.add(DsLandGrid.cells.first),
        throwsUnsupportedError,
      );
    });

    test('each cell carries its center and the shared dot opacity', () {
      for (final cell in DsLandGrid.cells) {
        expect(cell.longitude, DsLandGrid.centerLongitude(cell.col));
        expect(cell.latitude, DsLandGrid.centerLatitude(cell.row));
        expect(cell.opacity, DsColors.landDotOpacity(cell.col, cell.row));
        expect(DsLandGrid.dotOpacity(cell.col, cell.row), cell.opacity);
        expect(cell.opacity, inInclusiveRange(0.45, 0.95));
      }
    });

    test('land cells have value equality', () {
      const a = DsLandCell(
        col: 1,
        row: 2,
        longitude: 3,
        latitude: 4,
        opacity: 0.5,
      );
      const b = DsLandCell(
        col: 1,
        row: 2,
        longitude: 3,
        latitude: 4,
        opacity: 0.5,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
