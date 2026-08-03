/// Lugar resuelto a partir de unas coordenadas: lo que hace falta para
/// rellenar la ubicación de un caso sin escribirla a mano.
///
/// [regionOrCity] es opcional porque un punto en mitad del mar o de un
/// desierto tiene país pero no municipio.
class ResolvedPlace {
  const ResolvedPlace({
    required this.country,
    required this.countryCode,
    this.regionOrCity,
  });

  final String country;

  /// Código ISO de dos letras, ya en mayúsculas.
  final String countryCode;
  final String? regionOrCity;
}
