import 'package:logix_optiflow/features/searchbooking/domain/geo_point.dart';
import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

class GetNearbyOpticalStoresUseCase {
  const GetNearbyOpticalStoresUseCase({required this.repository});

  static const defaultRadiusKm = 5.0;

  final StoreRepository repository;

  Future<List<OpticalStore>> execute(GeoPoint point, {double radiusKm = defaultRadiusKm}) =>
      repository.nearby(point.latitude, point.longitude, radiusKm);
}
