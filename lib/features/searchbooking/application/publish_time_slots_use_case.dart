import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';

/// Abre los turnos de un día: corta el rango [desde, hasta) en turnos de la duración indicada y los
/// publica juntos con `POST optical-stores/{id}/time-slots`.
class PublishTimeSlotsUseCase {
  const PublishTimeSlotsUseCase({required this.repository});

  final StoreRepository repository;

  /// [from] y [to] son minutos desde la medianoche en la hora de la óptica (Lima, UTC-5).
  Future<List<TimeSlot>> execute(String storeId, DateTime day, int from, int to, int minutes) {
    final slots = slotsFor(day, from, to, minutes);
    if (slots.isEmpty) throw ApiException('El rango no alcanza para un turno.');
    return repository.publishTimeSlots(storeId, slots);
  }

  /// Inicio y fin (en UTC) de cada turno del rango.
  static List<(DateTime, DateTime)> slotsFor(DateTime day, int from, int to, int minutes) {
    final midnight = DateTime.utc(day.year, day.month, day.day).add(const Duration(hours: 5));
    return [
      for (var start = from; start + minutes <= to; start += minutes)
        (midnight.add(Duration(minutes: start)), midnight.add(Duration(minutes: start + minutes))),
    ];
  }
}
