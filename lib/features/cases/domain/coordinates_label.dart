/// Formato editorial de coordenadas del archivo: "37.77° N · 122.42° O".
///
/// Vive aparte del caso porque el formulario de alta lo necesita antes de que
/// exista un caso: al marcar el punto en el mapa sólo hay dos números.
String formatCoordinates(double latitude, double longitude) {
  final lat = latitude.abs().toStringAsFixed(2);
  final lng = longitude.abs().toStringAsFixed(2);
  final latHemisphere = latitude >= 0 ? 'N' : 'S';
  final lngHemisphere = longitude >= 0 ? 'E' : 'O';
  return '$lat° $latHemisphere · $lng° $lngHemisphere';
}
