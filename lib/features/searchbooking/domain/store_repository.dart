import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';

class StoreSearchResult {
  const StoreSearchResult({required this.stores, this.message});

  final List<OpticalStore> stores;
  final String? message;
}

abstract class StoreRepository {
  Future<List<OpticalStore>> list({String? name, String? address});

  Future<StoreSearchResult> search({String? name, String? address, double? minRating});

  Future<List<TimeSlot>> availability(String storeId);

  Future<List<OpticalStore>> nearby(double latitude, double longitude, double radiusKm);

  Future<void> saveFavorite(String patientId, String opticalStoreId);

  /// Califica la óptica de 1 a 5; el backend acepta una sola calificación por paciente.
  Future<void> rate(String opticalStoreId, String patientId, int score, String? comment);
}
