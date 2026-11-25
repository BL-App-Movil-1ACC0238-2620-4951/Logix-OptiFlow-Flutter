import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_store_time_slots_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/publish_time_slots_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';

/// Días que el admin puede abrir, desde hoy.
const scheduleDays = 14;

const slotMinutes = [30, 45];

class ScheduleUiState {
  ScheduleUiState({
    this.loading = true,
    DateTime? day,
    this.from = '09:00',
    this.to = '13:00',
    this.minutes = 30,
    this.slots = const [],
    this.saving = false,
    this.message,
    this.error,
  }) : day = day ?? StoreTime.today();

  final bool loading;
  /// Día elegido, en la fecha de la óptica.
  final DateTime day;
  final String from;
  final String to;
  final int minutes;
  final List<TimeSlot> slots;
  final bool saving;
  final String? message;
  final String? error;

  List<TimeSlot> get daySlots => slots.where((s) => StoreTime.day(s.start) == day).toList();

  ScheduleUiState copyWith({
    bool? loading,
    DateTime? day,
    String? from,
    String? to,
    int? minutes,
    List<TimeSlot>? slots,
    bool? saving,
    ValueGetter<String?>? message,
    ValueGetter<String?>? error,
  }) {
    return ScheduleUiState(
      loading: loading ?? this.loading,
      day: day ?? this.day,
      from: from ?? this.from,
      to: to ?? this.to,
      minutes: minutes ?? this.minutes,
      slots: slots ?? this.slots,
      saving: saving ?? this.saving,
      message: message != null ? message() : this.message,
      error: error != null ? error() : this.error,
    );
  }
}

/// Abre turnos de atención de la óptica del admin (`POST optical-stores/{id}/time-slots`).
class ScheduleViewModel extends ChangeNotifier {
  ScheduleViewModel({required this.getStoreTimeSlotsUseCase, required this.publishTimeSlotsUseCase});

  final GetStoreTimeSlotsUseCase getStoreTimeSlotsUseCase;
  final PublishTimeSlotsUseCase publishTimeSlotsUseCase;

  static final _hour = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  ScheduleUiState _state = ScheduleUiState();
  ScheduleUiState get state => _state;
  String? _storeId;
  bool _disposed = false;

  void _emit(ScheduleUiState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load(String? storeId) async {
    if (storeId == null || storeId.isEmpty) return;
    _storeId = storeId;
    try {
      final list = await getStoreTimeSlotsUseCase.execute(storeId);
      _emit(_state.copyWith(loading: false, slots: list));
    } catch (e) {
      _emit(_state.copyWith(loading: false, error: () => _message(e, 'No se pudieron cargar los turnos.')));
    }
  }

  void selectDay(DateTime day) => _emit(_state.copyWith(day: day, message: () => null, error: () => null));

  void setFrom(String value) => _emit(_state.copyWith(from: value));

  void setTo(String value) => _emit(_state.copyWith(to: value));

  void setMinutes(int value) => _emit(_state.copyWith(minutes: value));

  /// Turnos que se crearían con los datos actuales; null si las horas no son válidas.
  int? get preview {
    final from = _parse(_state.from);
    final to = _parse(_state.to);
    if (from == null || to == null || to <= from) return null;
    return PublishTimeSlotsUseCase.slotsFor(_state.day, from, to, _state.minutes).length;
  }

  Future<void> submit() async {
    final s = _state;
    final store = _storeId;
    if (store == null) return;
    final from = _parse(s.from);
    final to = _parse(s.to);
    if (from == null || to == null) {
      _emit(s.copyWith(error: () => 'Escribe las horas como HH:mm, por ejemplo 09:00.'));
      return;
    }
    if (to <= from) {
      _emit(s.copyWith(error: () => 'La hora de fin debe ser posterior a la de inicio.'));
      return;
    }
    final now = StoreTime.clock(DateTime.now());
    if (s.day == StoreTime.today() && from <= now.hour * 60 + now.minute) {
      _emit(s.copyWith(error: () => 'Hoy solo se pueden abrir turnos que empiecen más tarde.'));
      return;
    }
    final overlaps = PublishTimeSlotsUseCase.slotsFor(s.day, from, to, s.minutes)
        .any((slot) => s.daySlots.any((open) => open.start.isBefore(slot.$2) && slot.$1.isBefore(open.end)));
    if (overlaps) {
      _emit(s.copyWith(error: () => 'Ya hay turnos abiertos en ese rango. Elige otro horario.'));
      return;
    }
    if (s.saving) return;
    _emit(s.copyWith(saving: true, error: () => null, message: () => null));
    try {
      final created = await publishTimeSlotsUseCase.execute(store, s.day, from, to, s.minutes);
      _emit(_state.copyWith(saving: false, message: () => 'Se abrieron ${created.length} turnos.'));
      await load(store);
    } catch (e) {
      _emit(_state.copyWith(saving: false, error: () => _message(e, 'No se pudieron abrir los turnos.')));
    }
  }

  /// Minutos desde la medianoche; acepta "9:00" como "09:00".
  int? _parse(String value) {
    final match = _hour.firstMatch(value.length == 4 ? '0$value' : value);
    return match == null ? null : int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;
}
