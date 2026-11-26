import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

/// Venta del paciente que todavía no se cerró, para "Ventas por cerrar" en la ficha.
class StaffOpenSale {
  const StaffOpenSale({required this.id, required this.statusLabel, required this.detail});
  final String id;
  final String statusLabel;
  final String detail;
}

class StaffPatientsUiState {
  const StaffPatientsUiState({
    this.patients = const [],
    this.patientsById = const {},
    this.loading = false,
    this.error,
    this.patientsWithRecords,
    this.summaryError,
    this.saving = false,
    this.saveError,
    this.recordLoading = const {},
    this.recordErrors = const {},
    this.recordSectionErrors = const {},
    this.recordClinical = const {},
    this.recordAppointments = const {},
    this.recordOrders = const {},
    this.cancelling = false,
    this.recordOpenSales = const {},
  });

  final List<StaffPatient> patients;
  final Map<String, StaffPatient> patientsById;
  final bool loading;
  final String? error;
  final int? patientsWithRecords;
  final String? summaryError;
  final bool saving;
  final String? saveError;

  /// Ficha de cada paciente abierto, por id.
  final Set<String> recordLoading;
  final Map<String, String> recordErrors;
  final Map<String, Map<String, String>> recordSectionErrors;
  final Map<String, List<ClinicalRecord>> recordClinical;
  final Map<String, List<Appointment>> recordAppointments;
  final Map<String, List<StaffOrder>> recordOrders;
  final bool cancelling;
  final Map<String, List<StaffOpenSale>> recordOpenSales;

  StaffPatientsUiState copyWith({
    List<StaffPatient>? patients,
    Map<String, StaffPatient>? patientsById,
    bool? loading,
    ValueGetter<String?>? error,
    ValueGetter<int?>? patientsWithRecords,
    ValueGetter<String?>? summaryError,
    bool? saving,
    ValueGetter<String?>? saveError,
    Set<String>? recordLoading,
    Map<String, String>? recordErrors,
    Map<String, Map<String, String>>? recordSectionErrors,
    Map<String, List<ClinicalRecord>>? recordClinical,
    Map<String, List<Appointment>>? recordAppointments,
    Map<String, List<StaffOrder>>? recordOrders,
    bool? cancelling,
    Map<String, List<StaffOpenSale>>? recordOpenSales,
  }) {
    return StaffPatientsUiState(
      patients: patients ?? this.patients,
      patientsById: patientsById ?? this.patientsById,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      patientsWithRecords: patientsWithRecords != null ? patientsWithRecords() : this.patientsWithRecords,
      summaryError: summaryError != null ? summaryError() : this.summaryError,
      saving: saving ?? this.saving,
      saveError: saveError != null ? saveError() : this.saveError,
      recordLoading: recordLoading ?? this.recordLoading,
      recordErrors: recordErrors ?? this.recordErrors,
      recordSectionErrors: recordSectionErrors ?? this.recordSectionErrors,
      recordClinical: recordClinical ?? this.recordClinical,
      recordAppointments: recordAppointments ?? this.recordAppointments,
      recordOrders: recordOrders ?? this.recordOrders,
      cancelling: cancelling ?? this.cancelling,
      recordOpenSales: recordOpenSales ?? this.recordOpenSales,
    );
  }
}
