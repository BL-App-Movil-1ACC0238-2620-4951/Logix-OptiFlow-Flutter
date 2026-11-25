import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/application/book_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/cancel_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_store_availability_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_ui_state.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/mappers/patient_view_mapper.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';

/// Reserva y reprogramación de citas del paciente en cuatro pasos.
class BookingViewModel extends ChangeNotifier {
  BookingViewModel({
    required this.session,
    required this.patient,
    required this.stores,
    required this.getStoreAvailabilityUseCase,
    required this.bookAppointmentUseCase,
    required this.cancelAppointmentUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final PatientViewModel patient;
  final StoreSearchViewModel stores;
  final GetStoreAvailabilityUseCase getStoreAvailabilityUseCase;
  final BookAppointmentUseCase bookAppointmentUseCase;
  final CancelAppointmentUseCase cancelAppointmentUseCase;

  BookingUiState _state = BookingUiState(weekStart: _monday(DateTime.now()));
  BookingUiState get state => _state;
  @visibleForTesting
  set step(int value) => _state = _state.copyWith(step: value);
  int _bookingRequest = 0;

  PatientSession? get _current => session.session;

  void _emit(BookingUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _bookingRequest++;
    _emit(BookingUiState(weekStart: _state.weekStart, selectedDate: _state.selectedDate, selectedStoreIndex: _state.selectedStoreIndex));
  }

  bool get _locked => _state.loading || _state.appointment != null;

  Future<void> prepareBooking(String? storeId, {String? rescheduleId}) async {
    if (_state.loading && _state.step == 3) return;
    final request = ++_bookingRequest;
    final current = _current;
    bool active() => request == _bookingRequest && identical(current, _current);
    _emit(_state.copyWith(
      step: 1, selectedSlot: () => null, slots: const [], stores: const [], appointment: () => null,
      reschedulingId: () => rescheduleId, error: () => null, loading: true,
    ));
    try {
      if (rescheduleId != null) {
        await patient.refreshAppointments();
        if (!active()) return;
        final original = patient.appointmentById(rescheduleId);
        if (original == null || original.isPast || original.status == AppointmentStatus.cancelled || original.status == AppointmentStatus.completed) {
          throw ApiException(patient.state.appointmentsError ?? 'Esta cita no se puede reprogramar.');
        }
        storeId ??= original.opticalStoreId;
      }
      final loaded = await stores.loadStores(); // Always load all stores, independent of search filters.
      if (!active()) return;
      final options = [for (final store in loaded)
        if (const {'ACTIVE', 'OPEN', 'ABIERTO'}.contains(store.status.toUpperCase()))
          StoreOption(id: store.id, name: store.name, address: store.address,
            distance: '', availability: 'Consultar horarios', availableToday: false),
      ];
      final index = options.indexWhere((s) => s.id == storeId);
      _state = _state.copyWith(
        stores: options,
        selectedStoreIndex: index < 0 ? 0 : index,
        error: options.isEmpty ? () => 'No hay ópticas disponibles para reservar.' : null,
      );
    } catch (e) {
      if (active()) _state = _state.copyWith(error: () => e is ApiException ? e.message : 'No se pudieron cargar las ópticas.');
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }

  void selectStore(int index) {
    if (_locked || index < 0 || index >= _state.stores.length) return;
    _emit(_state.copyWith(selectedStoreIndex: index, selectedSlot: () => null, slots: const [], error: () => null));
  }

  Future<void> continueFromStore() async {
    if (_locked) return;
    final store = _state.selectedStore;
    if (store?.id == null) return;
    final request = ++_bookingRequest;
    final current = _current;
    bool active() => request == _bookingRequest && identical(current, _current);
    _emit(_state.copyWith(step: 2, loading: true, slots: const [], selectedSlot: () => null, selectedDate: () => null, error: () => null));
    try {
      final available = await getStoreAvailabilityUseCase.execute(store!.id!);
      if (!active()) return;
      final now = DateTime.now();
      final slots = [for (final slot in available)
        if (slot.opticalStoreId == store.id && slot.start.isAfter(now) && slot.status.toUpperCase() == 'AVAILABLE')
          PatientViewMapper.slot(slot),
      ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      final first = slots.firstOrNull?.date;
      _state = _state.copyWith(slots: slots, selectedDate: () => first, weekStart: _monday(first ?? now));
    } catch (e) {
      if (active()) _state = _state.copyWith(error: () => e is ApiException ? e.message : 'No se pudieron cargar los horarios.');
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }

  void shiftWeek(int weeks) {
    if (_locked) return;
    final weekStart = _state.weekStart.add(Duration(days: 7 * weeks));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final selected = days.firstWhere(hasSlots, orElse: () => days.first);
    _emit(_state.copyWith(weekStart: weekStart, selectedDate: () => selected, selectedSlot: () => null));
  }

  void selectDate(DateTime date) {
    if (_locked) return;
    _emit(_state.copyWith(selectedDate: () => DateTime(date.year, date.month, date.day), selectedSlot: () => null));
  }

  void selectSlot(SlotOption slot) {
    if (_locked || !_state.slots.contains(slot)) return;
    _emit(_state.copyWith(selectedSlot: () => slot, error: () => null));
  }

  bool continueFromDate() {
    if (_state.loading) return false;
    final slot = _state.selectedSlot;
    if (slot?.id == null || !slot!.startsAt.isAfter(DateTime.now())) {
      _emit(_state.copyWith(error: () => 'Selecciona un horario disponible para continuar.'));
      return false;
    }
    _emit(_state.copyWith(step: 3, error: () => null));
    return true;
  }

  void bookingBack() {
    if (_locked) return;
    if (_state.step > 1 && _state.step < 4) _emit(_state.copyWith(step: _state.step - 1, error: () => null));
  }

  Future<bool> confirmBooking() async {
    if (_state.loading || _state.step != 3) return false;
    final slot = _state.selectedSlot;
    final store = _state.selectedStore;
    final current = _current;
    if (slot?.id == null || store?.id == null || current?.isAuthenticated != true || current?.isPatient != true) {
      _emit(_state.copyWith(error: () => 'Inicia sesión como paciente y selecciona un horario real.'));
      return false;
    }
    if (_state.appointment == null && !slot!.startsAt.isAfter(DateTime.now())) {
      _emit(_state.copyWith(error: () => 'Ese horario ya pasó. Elige otro.'));
      return false;
    }
    final request = ++_bookingRequest;
    bool active() => request == _bookingRequest && identical(current, _current);
    _emit(_state.copyWith(loading: true, error: () => null));
    try {
      if (_state.appointment == null) {
        final created = await bookAppointmentUseCase.execute(patientId: current!.patientId, opticalStoreId: store!.id!, timeSlotId: slot!.id!);
        if (!active()) return false;
        _state = _state.copyWith(appointment: () => created);
        patient.putAppointment(created);
      }
      // The backend implements rescheduling as book-new, then cancel-old.
      // Keep the new id if cancellation fails, so retry never books it twice.
      final rescheduling = _state.reschedulingId;
      if (rescheduling != null) {
        final cancelled = await cancelAppointmentUseCase.execute(rescheduling);
        if (!active()) return false;
        patient.putAppointment(cancelled);
      }
      _state = _state.copyWith(step: 4);
      return true;
    } catch (e) {
      if (!active()) return false;
      if (_state.appointment != null && _state.reschedulingId != null) {
        _state = _state.copyWith(error: () => 'La nueva cita está reservada, pero no se pudo cancelar la anterior. Reintenta para completar la reprogramación; no se creará otra reserva.');
      } else if (e is ApiException && e.statusCode == 409) {
        _state = _state.copyWith(
          error: () => 'El horario ya no está disponible. Vuelve a elegir uno.',
          slots: _state.slots.where((s) => s.id != slot!.id).toList(),
          selectedSlot: () => null,
          step: 2,
        );
      } else {
        _state = _state.copyWith(error: () => e is ApiException ? e.message : 'No se pudo confirmar la reserva. Revisa tus citas antes de intentar de nuevo.');
      }
      return false;
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }

  List<SlotOption> slotsFor(DateTime? date) {
    if (date == null) return const [];
    return _state.slots.where((s) => _sameDay(s.date, date)).toList();
  }

  bool hasSlots(DateTime date) => _state.slots.any((s) => _sameDay(s.date, date));

  static DateTime _monday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
