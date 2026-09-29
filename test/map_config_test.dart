import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';

void main() {
  test('las teselas de producción no dependen de una clave de API', () {
    final config = MapConfig.production();

    expect(config.tileUrlTemplate, isNot(contains('cartocdn')));
    expect(config.tileUrlTemplate, contains('{z}'));
    expect(config.tileUrlTemplate, contains('{y}'));
    expect(config.tileUrlTemplate, contains('{x}'));
  });

  test('la atribución nombra a Esri y a los datos de OpenStreetMap', () {
    final attribution = MapConfig.production().attribution;

    expect(attribution, contains('Esri'));
    expect(attribution, contains('OpenStreetMap'));
  });
}
