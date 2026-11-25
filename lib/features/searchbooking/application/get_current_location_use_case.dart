import 'package:logix_optiflow/features/searchbooking/domain/geo_point.dart';
import 'package:logix_optiflow/features/searchbooking/domain/location_provider.dart';

class GetCurrentLocationUseCase {
  const GetCurrentLocationUseCase({required this.provider});

  final LocationProvider provider;

  /// Pide el permiso de ubicación cuando [ask] es true y devuelve la ubicación, si la hay.
  Future<GeoPoint?> execute({bool ask = false}) async {
    if (ask) await provider.requestPermission();
    return provider.current();
  }
}
