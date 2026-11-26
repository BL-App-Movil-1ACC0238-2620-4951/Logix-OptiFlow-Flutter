import 'dart:math';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Distancia en línea recta (fórmula de Haversine).
  double distanceKmTo(GeoPoint other) {
    const earthRadiusKm = 6371.0;
    double rad(double degrees) => degrees * pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    final a = pow(sin(dLat / 2), 2) + cos(rad(latitude)) * cos(rad(other.latitude)) * pow(sin(dLng / 2), 2);
    return 2 * earthRadiusKm * asin(sqrt(a));
  }
}
