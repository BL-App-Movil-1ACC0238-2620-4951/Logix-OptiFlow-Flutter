import 'package:logix_optiflow/features/searchbooking/domain/geo_point.dart';

/// Ubicación del celular.
abstract class LocationProvider {
  /// Pide el permiso si aún no se pidió. Devuelve si quedó concedido.
  Future<bool> requestPermission();

  /// Ubicación actual, o null si no hay permiso o el GPS está apagado.
  Future<GeoPoint?> current();
}
