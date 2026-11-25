import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/application/get_patient_clinical_records_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_prescription_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_quotation_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_sale_use_case.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/production/application/get_patient_work_orders_use_case.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';
import 'package:logix_optiflow/features/searchbooking/application/cancel_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_patient_appointments_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/rate_optical_store_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_ui_state.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/mappers/patient_view_mapper.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';

/// Inicio del paciente: citas, pedidos, historial, receta y notificaciones.
class PatientViewModel extends ChangeNotifier {
  PatientViewModel({
    required this.session,
    required this.stores,
    required this.getPatientAppointmentsUseCase,
    required this.cancelAppointmentUseCase,
    required this.getPatientWorkOrdersUseCase,
    required this.getPatientClinicalRecordsUseCase,
    required this.rateOpticalStoreUseCase,
    required this.getPrescriptionUseCase,
    required this.getSaleUseCase,
    required this.getQuotationUseCase,
  }) {
    session.addSessionReadyListener(_onSessionReady);
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final StoreSearchViewModel stores;
  final GetPatientAppointmentsUseCase getPatientAppointmentsUseCase;
  final CancelAppointmentUseCase cancelAppointmentUseCase;
  final GetPatientWorkOrdersUseCase getPatientWorkOrdersUseCase;
  final GetPatientClinicalRecordsUseCase getPatientClinicalRecordsUseCase;
  final RateOpticalStoreUseCase rateOpticalStoreUseCase;
  final GetPrescriptionUseCase getPrescriptionUseCase;
  final GetSaleUseCase getSaleUseCase;
  final GetQuotationUseCase getQuotationUseCase;

  PatientUiState _state = PatientUiState();
  PatientUiState get state => _state;
  int _appointmentsRequest = 0;
  Map<String, ClinicalRecord> _recordsById = const {};

  PatientSession? get _current => session.session;

  void _emit(PatientUiState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> _onSessionReady() async {
    if (_current?.isPatient != true) _emit(_state.copyWith(patientLoading: false));
    if (_current?.isPatient == true) unawaited(refreshPatient());
  }

  void _reset() {
    _appointmentsRequest++;
    _recordsById = const {};
    _emit(PatientUiState(patientLoading: false));
  }

  List<AppointmentUi> get upcoming => _state.appointments
      .where((a) => !a.isPast && a.status != AppointmentStatus.cancelled && a.status != AppointmentStatus.completed)
      .toList();
  AppointmentUi? get nextAppointment => upcoming.isEmpty ? null : upcoming.first;

  AppointmentUi? appointmentById(String id) => _state.appointments.where((item) => item.id == id).firstOrNull;

  OrderUi? orderById(String id) => _state.orders.where((item) => item.id == id).firstOrNull;

  AppointmentUi _appointmentView(Appointment appt) {
    final store = stores.state.stores.where((s) => s.id == appt.opticalStoreId).firstOrNull;
    final status = AppointmentStatusLabel.fromApi(appt.status);
    return PatientViewMapper.appointment(
      id: appt.id, start: appt.start, end: appt.end,
      opticalStoreId: appt.opticalStoreId, timeSlotId: appt.timeSlotId,
      title: 'Evaluación visual', storeName: store?.name ?? 'Óptica',
      storeAddress: store?.address ?? '', status: status,
      isPast: appt.end.isBefore(DateTime.now()) || status == AppointmentStatus.completed,
      fromApi: true,
    );
  }

  /// Agrega o reemplaza una cita ya guardada en el backend. Descarta las cargas anteriores en vuelo,
  /// para que no devuelvan el estado viejo.
  void putAppointment(Appointment appt) {
    _appointmentsRequest++;
    _emit(_state.copyWith(
      appointmentsLoading: false,
      appointments: [for (final item in _state.appointments) if (item.id != appt.id) item, _appointmentView(appt)]
        ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!)),
    ));
  }

  Future<void> refreshAppointments() async {
    final current = _current;
    if (current?.isAuthenticated != true || !current!.isPatient) return;
    final request = ++_appointmentsRequest;
    _emit(_state.copyWith(appointmentsLoading: true, appointmentsError: () => null));
    bool active() => identical(current, _current) && request == _appointmentsRequest;
    try {
      final storeRequest = stores.loadStores().catchError((_) => stores.state.stores);
      final results = await getPatientAppointmentsUseCase.execute(current.patientId);
      await storeRequest;
      if (!active()) return;
      _state = _state.copyWith(
        appointments: results.map(_appointmentView).toList()..sort((a, b) => a.startsAt!.compareTo(b.startsAt!)),
      );
    } catch (e) {
      if (active()) {
        _state = _state.copyWith(appointmentsError: () => e is ApiException ? e.message : 'No se pudieron cargar tus citas. Intenta nuevamente.');
      }
    } finally {
      if (active()) _emit(_state.copyWith(appointmentsLoading: false));
    }
  }

  Future<void> refreshPatient() async {
    final current = _current;
    if (current?.isAuthenticated != true || !current!.isPatient) return;
    _emit(_state.copyWith(patientLoading: true));
    final appointmentsRequest = refreshAppointments();
    List<WorkOrder> apiOrders = const [];
    List<ClinicalRecord> records = const [];
    try { apiOrders = await getPatientWorkOrdersUseCase.execute(current.patientId); } catch (_) {}
    if (!identical(current, _current)) return;
    try { records = await getPatientClinicalRecordsUseCase.execute(current.patientId); } catch (_) {}
    await appointmentsRequest;
    final products = await Future.wait(apiOrders.map(_productsOf));
    if (!identical(current, _current)) return;
    final name = session.displayName;
    final storeNames = {for (final store in stores.state.stores) store.id: store.name};
    final orders = [
      for (final (i, order) in apiOrders.indexed)
        PatientViewMapper.order(order, items: products[i], storeName: storeNames[order.opticalStoreId]),
    ];
    final history = records.map(PatientViewMapper.history).toList();
    _recordsById = {for (final r in records) if (r.id != null) r.id!: r};
    _emit(_state.copyWith(
      orders: orders,
      history: history,
      prescription: () => PatientViewMapper.prescription(records, name),
      prescriptions: PatientViewMapper.prescriptionItems(records),
      patientLoading: false,
    ));
  }

  /// Productos del pedido: venta → cotización → ítems. Sin venta o si falla, lista vacía.
  Future<List<QuotationItem>> _productsOf(WorkOrder order) async {
    final saleId = order.saleId;
    if (saleId == null) return const [];
    try {
      final sale = await getSaleUseCase.execute(saleId);
      return (await getQuotationUseCase.execute(sale.quotationId)).items;
    } catch (_) {
      return const [];
    }
  }

  /// Carga una receta con `GET clinical-records/{id}/prescription`.
  Future<void> loadPrescription(String recordId) async {
    final record = _recordsById[recordId];
    _emit(_state.copyWith(selectedPrescription: () => null, selectedPrescriptionError: () => null));
    try {
      final values = await getPrescriptionUseCase.execute(recordId);
      _emit(_state.copyWith(selectedPrescription: () => PatientViewMapper.prescriptionUi(values, record?.examinationDate, record?.observations, session.displayName)));
    } catch (error) {
      _emit(_state.copyWith(selectedPrescriptionError: () => error is ApiException ? error.message : 'No se pudo cargar la receta.'));
    }
  }

  Future<bool> cancelAppointment(String id) async {
    if (_state.appointmentActionLoading) return false;
    final current = _current;
    final item = appointmentById(id);
    if (current?.isAuthenticated != true || current?.isPatient != true || item == null || !item.fromApi) return false;
    _emit(_state.copyWith(appointmentActionLoading: true, appointmentActionError: () => null));
    try {
      final updated = await cancelAppointmentUseCase.execute(id);
      if (!identical(current, _current)) return false;
      putAppointment(updated);
      return true;
    } catch (e) {
      if (identical(current, _current)) {
        _state = _state.copyWith(appointmentActionError: () => e is ApiException ? e.message : 'No se pudo cancelar la cita.');
      }
      return false;
    } finally {
      if (identical(current, _current)) _emit(_state.copyWith(appointmentActionLoading: false));
    }
  }

  /// Califica la óptica de una cita atendida. Devuelve el error o null; un 409 significa que ya estaba calificada.
  Future<String?> rateStore(String storeId, int score, String comment) async {
    final current = _current;
    if (current?.isAuthenticated != true || current?.isPatient != true) return 'Inicia sesión como paciente para calificar.';
    String? error;
    var rated = false;
    try {
      await rateOpticalStoreUseCase.execute(
        opticalStoreId: storeId,
        patientId: current!.patientId,
        score: score,
        comment: comment.trim().isEmpty ? null : comment.trim(),
      );
      rated = true;
    } on ApiException catch (e) {
      rated = e.statusCode == 409;
      error = e.message;
    } catch (_) {
      error = 'No se pudo enviar la calificación.';
    }
    if (rated && identical(current, _current)) _emit(_state.copyWith(ratedStoreIds: {..._state.ratedStoreIds, storeId}));
    return error;
  }
}
