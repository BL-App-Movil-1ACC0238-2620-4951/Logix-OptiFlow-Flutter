import '../entities/models.dart';
import '../repositories/store_repository.dart';

class GetOpticalStores {
  const GetOpticalStores(this._stores);

  final StoreRepository _stores;

  Future<List<OpticalStore>> call({String? name, String? address}) {
    return _stores.list(name: name, address: address);
  }
}

class SearchOpticalStores {
  const SearchOpticalStores(this._stores);

  final StoreRepository _stores;

  Future<StoreSearchResult> call({String? name, String? address, double? minRating}) {
    return _stores.search(name: name, address: address, minRating: minRating);
  }
}

class GetStoreAvailability {
  const GetStoreAvailability(this._stores);

  final StoreRepository _stores;

  Future<List<TimeSlot>> call(String storeId) => _stores.availability(storeId);
}
