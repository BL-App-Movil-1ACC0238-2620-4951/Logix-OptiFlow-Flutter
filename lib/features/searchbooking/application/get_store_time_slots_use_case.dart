import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';

/// Todos los turnos publicados de una óptica (libres y reservados), en orden.
class GetStoreTimeSlotsUseCase {
  const GetStoreTimeSlotsUseCase({required this.repository});

  final StoreRepository repository;

  Future<List<TimeSlot>> execute(String storeId) async =>
      (await repository.timeSlots(storeId))..sort((a, b) => a.start.compareTo(b.start));
}
