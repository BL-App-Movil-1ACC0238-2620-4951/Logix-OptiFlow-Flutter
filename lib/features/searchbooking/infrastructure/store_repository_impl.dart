import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl({required this.api});

  final SearchBookingApi api;

  @override
  Future<List<OpticalStore>> list({String? name, String? address}) async {
    final stores = await api.listStores(name: name, address: address);
    return stores.map((store) => store.toEntity()).toList();
  }

  @override
  Future<StoreSearchResult> search({String? name, String? address, double? minRating}) async {
    final result = await api.searchStores(name: name, address: address, minRating: minRating);
    return StoreSearchResult(
      stores: result.stores.map((store) => store.toEntity()).toList(),
      message: result.message,
    );
  }

  @override
  Future<List<OpticalStore>> nearby(double latitude, double longitude, double radiusKm) async {
    final stores = await api.nearbyStores(latitude, longitude, radiusKm);
    return stores.map((store) => store.toEntity()).toList();
  }

  @override
  Future<void> saveFavorite(String patientId, String opticalStoreId) => api.saveFavoriteStore(patientId, opticalStoreId);

  @override
  Future<void> rate(String opticalStoreId, String patientId, int score, String? comment) =>
      api.rateOpticalStore(opticalStoreId, patientId, score, comment);

  @override
  Future<List<TimeSlot>> timeSlots(String storeId) async => (await api.availability(storeId)).map((slot) => slot.toEntity()).toList();

  @override
  Future<List<TimeSlot>> publishTimeSlots(String storeId, List<(DateTime, DateTime)> slots) async =>
      (await api.publishTimeSlots(storeId, slots)).map((slot) => slot.toEntity()).toList();

  @override
  Future<List<TimeSlot>> availability(String storeId) async {
    final slots = await api.availability(storeId);
    return slots
        .map((slot) => slot.toEntity())
        .where((slot) => slot.status.toUpperCase() == 'AVAILABLE')
        .toList();
  }
}
