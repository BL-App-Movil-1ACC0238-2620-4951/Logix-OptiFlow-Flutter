import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_repository.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/clinical_api.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

/// Usa la API clínica y, para la ficha del paciente y sus citas, la de Search & Booking.
class ClinicalRepositoryImpl implements ClinicalRepository {
  const ClinicalRepositoryImpl({required this.api, required this.bookingApi});

  final ClinicalApi api;
  final SearchBookingApi bookingApi;

  @override
  Future<StaffPatient> patient(String id) => bookingApi.staffPatient(id);
  @override
  Future<List<Appointment>> appointments(String patientId) async => (await bookingApi.appointments(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<List<ClinicalRecord>> records(String patientId) async => (await api.clinicalRecords(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<ClinicalRecord> examine({required String patientId, required String appointmentId, required String observations}) => api.examine(patientId: patientId, appointmentId: appointmentId, observations: observations);
  @override
  Future<ClinicalRecord> saveHistory(String recordId, MedicalHistory history) => api.saveMedicalHistory(recordId, history);
  @override
  Future<PrescriptionValues> prescribe(String recordId, PrescriptionValues values) => api.generatePrescription(recordId, values);
  @override
  Future<PrescriptionValues> prescription(String recordId) => api.prescription(recordId);
  @override
  Future<Appointment> complete(String appointmentId) async => (await bookingApi.completeAppointment(appointmentId)).toEntity();
  @override
  Future<int> patientsWithRecords() => api.patientsWithRecords();
}
