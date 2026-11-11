import '../entities/models.dart';

class StoreSearchResult {
  const StoreSearchResult({required this.stores, this.message});

  final List<OpticalStore> stores;
  final String? message;
}

abstract class StoreRepository {
  Future<List<OpticalStore>> list({String? name, String? address});

  Future<StoreSearchResult> search({String? name, String? address, double? minRating});

  Future<List<TimeSlot>> availability(String storeId);
}
