import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

/// Primer turno libre (desde ahora) de cada óptica; las que no tienen turnos no aparecen.
class GetFirstAvailableSlotsUseCase {
  const GetFirstAvailableSlotsUseCase({required this.repository});

  final StoreRepository repository;

  Future<Map<String, DateTime>> execute(List<String> storeIds) async {
    final now = DateTime.now();
    final entries = await Future.wait(storeIds.toSet().map((id) async {
      try {
        final starts = (await repository.availability(id)).map((slot) => slot.start).where((start) => start.isAfter(now)).toList()..sort();
        return starts.isEmpty ? null : MapEntry(id, starts.first);
      } catch (_) {
        return null;
      }
    }));
    return Map.fromEntries(entries.whereType<MapEntry<String, DateTime>>());
  }
}
