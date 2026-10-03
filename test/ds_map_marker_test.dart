import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

DsMapMarker _marker({
  String id = 'a',
  String label = 'Alpha',
  double latitude = 40,
  double longitude = -4,
  Color color = const Color(0xFFFF0000),
  int year = 1990,
}) => DsMapMarker(
  id: id,
  label: label,
  latitude: latitude,
  longitude: longitude,
  color: color,
  year: year,
);

void main() {
  group('DsMapMarker', () {
    test('exposes the values it was built with', () {
      final marker = _marker();
      expect(marker.id, 'a');
      expect(marker.label, 'Alpha');
      expect(marker.latitude, 40);
      expect(marker.longitude, -4);
      expect(marker.color, const Color(0xFFFF0000));
      expect(marker.year, 1990);
    });

    test('is a const-constructible value class', () {
      const marker = DsMapMarker(
        id: 'a',
        label: 'Alpha',
        latitude: 1,
        longitude: 2,
        color: Color(0xFF00FF00),
        year: 2000,
      );
      expect(marker.id, 'a');
    });

    test('equal values are equal and share a hash code', () {
      expect(_marker(), _marker());
      expect(_marker().hashCode, _marker().hashCode);
    });

    test('differs when any field differs', () {
      final base = _marker();
      expect(base, isNot(_marker(id: 'b')));
      expect(base, isNot(_marker(label: 'Beta')));
      expect(base, isNot(_marker(latitude: 41)));
      expect(base, isNot(_marker(longitude: -5)));
      expect(base, isNot(_marker(color: const Color(0xFF0000FF))));
      expect(base, isNot(_marker(year: 1991)));
    });
  });
}
