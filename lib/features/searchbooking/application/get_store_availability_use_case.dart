import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';

class GetStoreAvailabilityUseCase {
  const GetStoreAvailabilityUseCase({required this.repository});

  final StoreRepository repository;

  Future<List<TimeSlot>> execute(String storeId) => repository.availability(storeId);
}
