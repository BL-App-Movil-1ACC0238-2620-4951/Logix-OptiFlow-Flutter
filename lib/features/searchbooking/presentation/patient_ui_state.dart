import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/presentation/models/ui_models.dart';

class PatientUiState {
  const PatientUiState({
    this.appointments = const [],
    this.appointmentsLoading = false,
    this.appointmentsError,
    this.appointmentActionLoading = false,
    this.appointmentActionError,
    this.orders = const [],
    this.history = const [],
    this.prescription,
    this.prescriptions = const [],
    this.selectedPrescription,
    this.selectedPrescriptionError,
    this.patientLoading = true,
    this.ratedStoreIds = const {},
  });

  final List<AppointmentUi> appointments;
  final bool appointmentsLoading;
  final String? appointmentsError;
  final bool appointmentActionLoading;
  final String? appointmentActionError;
  final List<OrderUi> orders;
  final List<HistoryEntry> history;
  final PrescriptionUi? prescription;
  final List<PrescriptionItemUi> prescriptions;
  /// Receta abierta desde "Mis recetas"; null mientras se consulta.
  final PrescriptionUi? selectedPrescription;
  final String? selectedPrescriptionError;
  final bool patientLoading;
  /// Ópticas que el paciente ya calificó en esta sesión.
  final Set<String> ratedStoreIds;

  PatientUiState copyWith({
    List<AppointmentUi>? appointments,
    bool? appointmentsLoading,
    ValueGetter<String?>? appointmentsError,
    bool? appointmentActionLoading,
    ValueGetter<String?>? appointmentActionError,
    List<OrderUi>? orders,
    List<HistoryEntry>? history,
    ValueGetter<PrescriptionUi?>? prescription,
    List<PrescriptionItemUi>? prescriptions,
    ValueGetter<PrescriptionUi?>? selectedPrescription,
    ValueGetter<String?>? selectedPrescriptionError,
    bool? patientLoading,
    Set<String>? ratedStoreIds,
  }) {
    return PatientUiState(
      appointments: appointments ?? this.appointments,
      appointmentsLoading: appointmentsLoading ?? this.appointmentsLoading,
      appointmentsError: appointmentsError != null ? appointmentsError() : this.appointmentsError,
      appointmentActionLoading: appointmentActionLoading ?? this.appointmentActionLoading,
      appointmentActionError: appointmentActionError != null ? appointmentActionError() : this.appointmentActionError,
      orders: orders ?? this.orders,
      history: history ?? this.history,
      prescription: prescription != null ? prescription() : this.prescription,
      prescriptions: prescriptions ?? this.prescriptions,
      selectedPrescription: selectedPrescription != null ? selectedPrescription() : this.selectedPrescription,
      selectedPrescriptionError: selectedPrescriptionError != null ? selectedPrescriptionError() : this.selectedPrescriptionError,
      patientLoading: patientLoading ?? this.patientLoading,
      ratedStoreIds: ratedStoreIds ?? this.ratedStoreIds,
    );
  }
}
