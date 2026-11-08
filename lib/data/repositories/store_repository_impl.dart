import '../../core/network/optiflow_api.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._api);

  final OptiFlowApi _api;

  @override
  Future<List<OpticalStore>> list({String? name, String? address}) {
    return _api.listStores(name: name, address: address);
  }

  @override
  Future<StoreSearchResult> search({String? name, String? address, double? minRating}) async {
    final result = await _api.searchStores(name: name, address: address, minRating: minRating);
    return StoreSearchResult(stores: result.stores, message: result.message);
  }

  @override
  Future<List<TimeSlot>> availability(String storeId) {
    return _api.availability(storeId);
  }
}
