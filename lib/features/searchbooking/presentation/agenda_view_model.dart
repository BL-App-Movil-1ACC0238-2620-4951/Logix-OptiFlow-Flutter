import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/application/book_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_agenda_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patient_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_store_availability_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/agenda_item.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_ui_state.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/mappers/staff_view_mapper.dart';

/// Agenda de la óptica, inicio del personal y citas que agenda el personal.
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel({
    required this.session,
    required this.patients,
    required this.production,
    required this.stores,
    required this.getAgendaUseCase,
    required this.getStaffPatientUseCase,
    required this.getStoreAvailabilityUseCase,
    required this.bookAppointmentUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final StaffPatientsViewModel patients;
  final ProductionViewModel production;
  final StoreSearchViewModel stores;
  final GetAgendaUseCase getAgendaUseCase;
  final GetStaffPatientUseCase getStaffPatientUseCase;
  final GetStoreAvailabilityUseCase getStoreAvailabilityUseCase;
  final BookAppointmentUseCase bookAppointmentUseCase;

  AgendaUiState _state = AgendaUiState(date: StoreTime.today());
  AgendaUiState get state => _state;
  int _agendaRequest = 0;
  int _bookingRequest = 0;

  PatientSession? get _current => session.session;

  void _emit(AgendaUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _agendaRequest++;
    _bookingRequest++;
    _emit(AgendaUiState(date: StoreTime.today()));
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;

  Set<String> get waitingPatientIds =>
      _state.agenda.where((a) => a.status == AgendaStatus.waiting).map((a) => a.patientId).toSet();

  List<DateTime> get agendaWeek {
    final monday = _state.date.subtract(Duration(days: _state.date.weekday - DateTime.monday));
    return List.generate(6, (i) => monday.add(Duration(days: i)));
  }

  /// Carga lo que muestra el inicio del personal según su rol.
  Future<void> refreshStaffOverview() async {
    final current = _current;
    if (current?.isAuthenticated != true || current?.isPatient != false) return;
    final tasks = <Future<void>>[];
    if (session.canOpen('/s/patients')) tasks.add(patients.refreshStaffPatients());
    if (session.canOpen('/s/agenda')) tasks.add(refreshStaffAgenda());
    if (session.canOpen('/s/production')) tasks.add(production.refreshStaffOrders());
    tasks.add(() async { try { await stores.loadStores(); } catch (_) {} }());
    await Future.wait(tasks);
  }

  Future<void> refreshStaffAgenda({DateTime? date}) async {
    if (!session.canOpen('/s/agenda')) return;
    final current = _current;
    final storeId = current?.opticalStoreId;
    if (storeId == null || storeId.isEmpty) {
      _emit(_state.copyWith(error: () => 'Tu cuenta no tiene una óptica asignada.'));
      return;
    }
    final requestedDate = date ?? _state.date;
    final request = ++_agendaRequest;
    bool active() => identical(current, _current) && request == _agendaRequest;
    _emit(_state.copyWith(date: requestedDate, loading: true, error: () => null, agenda: const []));
    try {
      final loaded = await getAgendaUseCase.execute(storeId, requestedDate);
      final items = await Future.wait(loaded.where((a) => a.status != 'CANCELLED').map((appointment) async {
        var patient = patients.staffPatient(appointment.patientId);
        if (patient == null) { try { patient = await getStaffPatientUseCase.execute(appointment.patientId); } catch (_) {} }
        if (identical(current, _current) && patient != null) patients.cachePatient(patient);
        return StaffViewMapper.agenda(appointment, patient?.fullName ?? 'Paciente');
      }));
      if (!active()) return;
      _state = _state.copyWith(agenda: items..sort((a, b) => a.startsAt!.compareTo(b.startsAt!)));
    } catch (e) {
      if (active()) _state = _state.copyWith(error: () => _message(e, 'No se pudo cargar la agenda.'));
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }

  Future<void> prepareStaffBooking({String? patientId}) async {
    if (!session.canOpen('/s/appointments/new') || _state.bookingSaving) return;
    _state = _state.copyWith(bookingPatientId: () => patientId, bookingSlotId: () => null);
    await Future.wait([patients.refreshStaffPatients(), reloadStaffBookingSlots()]);
  }

  Future<void> reloadStaffBookingSlots() async {
    if (!session.canOpen('/s/appointments/new')) return;
    final current = _current;
    final storeId = current?.opticalStoreId;
    if (storeId == null || storeId.isEmpty) {
      _emit(_state.copyWith(bookingError: () => 'Tu cuenta no tiene una óptica asignada.'));
      return;
    }
    final request = ++_bookingRequest;
    bool active() => identical(current, _current) && request == _bookingRequest;
    _emit(_state.copyWith(bookingLoading: true, bookingError: () => null, bookingSlots: const [], bookingSlotId: () => null));
    try {
      final loaded = await getStoreAvailabilityUseCase.execute(storeId);
      if (!active()) return;
      final slots = loaded.where((s) => s.opticalStoreId == storeId && s.status == 'AVAILABLE' && s.start.isAfter(DateTime.now())).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      _state = _state.copyWith(bookingSlots: slots, bookingDay: () => slots.isEmpty ? null : StoreTime.day(slots.first.start));
    } catch (e) {
      if (active()) _state = _state.copyWith(bookingError: () => _message(e, 'No se pudieron cargar los horarios.'));
    } finally {
      if (active()) _emit(_state.copyWith(bookingLoading: false));
    }
  }

  void selectStaffBooking({String? patientId, DateTime? day, String? slotId}) {
    if (_state.bookingSaving) return;
    var next = _state;
    if (patientId != null) next = next.copyWith(bookingPatientId: () => patientId);
    if (day != null) next = next.copyWith(bookingDay: () => day, bookingSlotId: () => null);
    if (slotId != null) next = next.copyWith(bookingSlotId: () => slotId);
    _emit(next.copyWith(bookingError: () => null));
  }

  Future<bool> confirmStaffBooking() async {
    if (_state.bookingSaving || _state.bookingLoading || !session.canOpen('/s/appointments/new')) return false;
    final current = _current;
    final storeId = current?.opticalStoreId;
    final patientId = _state.bookingPatientId;
    final slot = _state.bookingSlots.where((s) => s.id == _state.bookingSlotId).firstOrNull;
    if (storeId == null || patientId == null || patients.staffPatient(patientId) == null || slot == null || !slot.start.isAfter(DateTime.now())) {
      _emit(_state.copyWith(bookingError: () => 'Elige un paciente registrado y un horario disponible.'));
      return false;
    }
    _emit(_state.copyWith(bookingSaving: true, bookingError: () => null));
    try {
      await bookAppointmentUseCase.execute(patientId: patientId, opticalStoreId: storeId, timeSlotId: slot.id);
      if (!identical(current, _current)) return false;
      _state = _state.copyWith(bookingSlots: _state.bookingSlots.where((s) => s.id != slot.id).toList(), bookingSlotId: () => null);
      await Future.wait([refreshStaffAgenda(), patients.loadStaffRecord(patientId)]);
      return identical(current, _current);
    } catch (e) {
      if (!identical(current, _current)) return false;
      final message = _message(e, 'No se pudo agendar la cita.');
      await reloadStaffBookingSlots();
      if (identical(current, _current)) _state = _state.copyWith(bookingError: () => message);
      return false;
    } finally {
      if (identical(current, _current)) _emit(_state.copyWith(bookingSaving: false));
    }
  }
}
