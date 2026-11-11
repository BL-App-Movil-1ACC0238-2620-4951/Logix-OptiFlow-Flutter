import '../datasources/optiflow_api.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._api);

  final OptiFlowApi _api;

  @override
  Future<List<OpticalStore>> list({String? name, String? address}) async {
    final stores = await _api.listStores(name: name, address: address);
    return stores.map((store) => store.toEntity()).toList();
  }

  @override
  Future<StoreSearchResult> search({String? name, String? address, double? minRating}) async {
    final result = await _api.searchStores(name: name, address: address, minRating: minRating);
    return StoreSearchResult(
      stores: result.stores.map((store) => store.toEntity()).toList(),
      message: result.message,
    );
  }

  @override
  Future<List<TimeSlot>> availability(String storeId) async {
    final slots = await _api.availability(storeId);
    return slots
        .map((slot) => slot.toEntity())
        .where((slot) => slot.status.toUpperCase() == 'AVAILABLE')
        .toList();
  }
}
