import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/application/get_patient_clinical_records_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_patient_sales_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_quotation_use_case.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/application/get_patients_with_records_use_case.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/production/application/get_staff_orders_use_case.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/searchbooking/application/cancel_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_patient_appointments_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patient_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patients_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/register_patient_by_staff_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_ui_state.dart';

/// Pacientes del personal: directorio, registro y ficha.
class StaffPatientsViewModel extends ChangeNotifier {
  StaffPatientsViewModel({
    required this.session,
    required this.getStaffPatientsUseCase,
    required this.getStaffPatientUseCase,
    required this.registerPatientByStaffUseCase,
    required this.getPatientsWithRecordsUseCase,
    required this.getPatientClinicalRecordsUseCase,
    required this.getPatientAppointmentsUseCase,
    required this.getStaffOrdersUseCase,
    required this.cancelAppointmentUseCase,
    required this.getPatientSalesUseCase,
    required this.getQuotationUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final GetStaffPatientsUseCase getStaffPatientsUseCase;
  final GetStaffPatientUseCase getStaffPatientUseCase;
  final RegisterPatientByStaffUseCase registerPatientByStaffUseCase;
  final GetPatientsWithRecordsUseCase getPatientsWithRecordsUseCase;
  final GetPatientClinicalRecordsUseCase getPatientClinicalRecordsUseCase;
  final GetPatientAppointmentsUseCase getPatientAppointmentsUseCase;
  final GetStaffOrdersUseCase getStaffOrdersUseCase;
  final CancelAppointmentUseCase cancelAppointmentUseCase;
  final GetPatientSalesUseCase getPatientSalesUseCase;
  final GetQuotationUseCase getQuotationUseCase;

  StaffPatientsUiState _state = const StaffPatientsUiState();
  StaffPatientsUiState get state => _state;
  int _patientsRequest = 0;
  final Map<String, int> _recordRequests = {};

  PatientSession? get _current => session.session;

  void _emit(StaffPatientsUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _patientsRequest++;
    for (final id in _recordRequests.keys.toList()) { _recordRequests[id] = _recordRequests[id]! + 1; }
    _emit(const StaffPatientsUiState());
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;

  StaffPatient? staffPatient(String id) => _state.patientsById[id];

  /// Guarda un paciente leído por otra pantalla (por ejemplo, la agenda).
  void cachePatient(StaffPatient patient) {
    _state = _state.copyWith(patientsById: {..._state.patientsById, patient.id: patient});
  }

  int get newPatientsThisMonth {
    final today = StoreTime.today();
    return _state.patients.where((p) {
      final date = p.createdAt == null ? null : StoreTime.day(p.createdAt!);
      return date?.year == today.year && date?.month == today.month;
    }).length;
  }

  Future<void> refreshStaffPatients() async {
    if (!session.canOpen('/s/patients')) return;
    final current = _current;
    final request = ++_patientsRequest;
    bool active() => identical(current, _current) && request == _patientsRequest;
    _emit(_state.copyWith(loading: true, error: () => null, summaryError: () => null));
    try {
      final loaded = await getStaffPatientsUseCase.execute();
      if (!active()) return;
      _emit(_state.copyWith(patients: loaded, patientsById: {..._state.patientsById, for (final patient in loaded) patient.id: patient}));
      try {
        final count = await getPatientsWithRecordsUseCase.execute();
        if (active()) _state = _state.copyWith(patientsWithRecords: () => count);
      } catch (e) {
        if (active()) _state = _state.copyWith(summaryError: () => _message(e, 'No se pudo cargar el resumen clínico.'));
      }
    } catch (e) {
      if (active()) _state = _state.copyWith(error: () => _message(e, 'No se pudieron cargar los pacientes.'));
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }

  Future<String?> registerStaffPatient({required String name, required String email, required String phone, required String dni, String birthDate = ''}) async {
    if (_state.saving) return null;
    final current = _current;
    final birth = birthDate.trim().isEmpty ? null : StoreTime.parseBirthDate(birthDate);
    String? error;
    if (!session.canOpen('/s/patients/new')) { error = 'Tu cuenta no puede registrar pacientes.'; }
    else if (name.trim().length < 2 || name.trim().length > 80) { error = 'Ingresa el nombre del paciente (2 a 80 caracteres).'; }
    else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) { error = 'Ingresa un correo válido.'; }
    else if (phone.trim().isEmpty) { error = 'Ingresa el teléfono del paciente.'; }
    else if (!RegExp(r'^\d{8}$').hasMatch(dni)) { error = 'El DNI debe tener 8 dígitos.'; }
    else if (birthDate.trim().isNotEmpty && birth == null) { error = 'La fecha de nacimiento no es válida.'; }
    if (error != null) {
      _emit(_state.copyWith(saveError: () => error));
      return null;
    }
    _emit(_state.copyWith(saving: true, saveError: () => null));
    try {
      final patient = await registerPatientByStaffUseCase.execute(name: name.trim(), email: email.trim(), phone: phone.trim(), dni: dni, birthDate: birth);
      if (!identical(current, _current)) return null;
      _patientsRequest++;
      _state = _state.copyWith(
        loading: false,
        patientsById: {..._state.patientsById, patient.id: patient},
        patients: [patient, ..._state.patients.where((p) => p.id != patient.id)],
      );
      return patient.id;
    } catch (e) {
      if (identical(current, _current)) _state = _state.copyWith(saveError: () => _message(e, 'No se pudo registrar al paciente.'));
      return null;
    } finally {
      if (identical(current, _current)) _emit(_state.copyWith(saving: false));
    }
  }

  Future<void> loadStaffRecord(String id) async {
    if (!session.canOpen('/s/patients')) return;
    final current = _current;
    final request = (_recordRequests[id] ?? 0) + 1;
    _recordRequests[id] = request;
    bool active() => identical(current, _current) && _recordRequests[id] == request;
    _emit(_state.copyWith(
      recordLoading: {..._state.recordLoading, id},
      recordErrors: Map.of(_state.recordErrors)..remove(id),
      recordSectionErrors: {..._state.recordSectionErrors, id: const {}},
    ));
    Future<Object> result(Future<Object> call) => call.then<Object>((value) => value, onError: (Object error) => error);
    try {
      final responses = await Future.wait<Object>([
        result(getStaffPatientUseCase.execute(id)), result(getPatientClinicalRecordsUseCase.execute(id)),
        result(getPatientAppointmentsUseCase.execute(id)), result(getStaffOrdersUseCase.execute()),
      ]);
      if (!active()) return;
      final patient = responses[0];
      if (patient is! StaffPatient) throw patient;
      final errors = <String, String>{};
      var next = _state.copyWith(patientsById: {..._state.patientsById, id: patient});
      if (responses[1] is List<ClinicalRecord>) { next = next.copyWith(recordClinical: {...next.recordClinical, id: responses[1] as List<ClinicalRecord>}); }
      else { errors['clinical'] = _message(responses[1], 'No se pudo cargar la receta.'); }
      if (responses[2] is List<Appointment>) { next = next.copyWith(recordAppointments: {...next.recordAppointments, id: responses[2] as List<Appointment>}); }
      else { errors['appointments'] = _message(responses[2], 'No se pudieron cargar las citas.'); }
      if (responses[3] is List<StaffOrder>) {
        next = next.copyWith(recordOrders: {...next.recordOrders, id: (responses[3] as List<StaffOrder>).where((o) => o.patientId == id).toList()});
      } else { errors['orders'] = _message(responses[3], 'No se pudieron cargar las órdenes.'); }
      _state = next.copyWith(recordSectionErrors: {...next.recordSectionErrors, id: errors});
    } catch (e) {
      if (active()) _state = _state.copyWith(recordErrors: {..._state.recordErrors, id: _message(e, 'No se encontró al paciente.')});
    } finally {
      if (active()) _emit(_state.copyWith(recordLoading: {..._state.recordLoading}..remove(id)));
    }
  }

  /// Cancela una cita desde la ficha y vuelve a leer la ficha. Devuelve el error, o null si salió bien.
  Future<String?> cancelRecordAppointment(String patientId, String appointmentId) async {
    if (_state.cancelling) return null;
    final current = _current;
    _emit(_state.copyWith(cancelling: true));
    try {
      await cancelAppointmentUseCase.execute(appointmentId);
      if (identical(current, _current)) await loadStaffRecord(patientId);
      return null;
    } catch (e) {
      return _message(e, 'No se pudo cancelar la cita.');
    } finally {
      if (identical(current, _current)) _emit(_state.copyWith(cancelling: false));
    }
  }

  /// Ventas sin cerrar del paciente (`GET patients/{id}/sales`), para cobrarlas o cerrarlas aunque sean de
  /// una ficha anterior. Sin pago el backend no manda el monto: se toma el total de la cotización.
  Future<void> loadOpenSales(String patientId) async {
    if (!session.canOpen('/s/sale')) return;
    final current = _current;
    try {
      final sales = (await getPatientSalesUseCase.execute(patientId)).where((s) => s.status != SaleStatus.closed).toList();
      final totals = await Future.wait(sales.map((sale) async {
        if (sale.amount != null) return sale.amount;
        try {
          return (await getQuotationUseCase.execute(sale.quotationId)).total;
        } catch (_) {
          return null;
        }
      }));
      if (!identical(current, _current)) return;
      final open = [
        for (var i = 0; i < sales.length; i++)
          StaffOpenSale(
            id: sales[i].id,
            statusLabel: sales[i].status == SaleStatus.paid ? 'Pagada · por cerrar' : 'Pendiente de pago',
            detail: _saleDetail(sales[i], totals[i]),
          ),
      ];
      _emit(_state.copyWith(recordOpenSales: {..._state.recordOpenSales, patientId: open}));
    } catch (_) {
      // Como en Kotlin: si falla, la sección simplemente no aparece.
    }
  }

  String _saleDetail(Sale sale, num? total) {
    final date = sale.paidAt ?? sale.closedAt ?? sale.issuedAt;
    final parts = [
      if (date != null) DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(date)),
      if (total != null) soles(total),
    ];
    return parts.isEmpty ? 'Venta registrada' : parts.join(' · ');
  }
}
