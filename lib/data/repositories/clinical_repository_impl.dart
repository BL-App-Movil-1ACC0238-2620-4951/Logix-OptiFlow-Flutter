import '../../domain/entities/appointment.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/clinical_repository.dart';
import '../datasources/optiflow_api.dart';

class ClinicalRepositoryImpl implements ClinicalRepository {
  const ClinicalRepositoryImpl(this._api);
  final OptiFlowApi _api;
  @override
  Future<StaffPatient> patient(String id) => _api.staffPatient(id);
  @override
  Future<List<Appointment>> appointments(String patientId) async => (await _api.appointments(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<List<ClinicalRecord>> records(String patientId) async => (await _api.clinicalRecords(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<ClinicalRecord> examine({required String patientId, required String appointmentId, required String observations}) => _api.examine(patientId: patientId, appointmentId: appointmentId, observations: observations);
  @override
  Future<ClinicalRecord> saveHistory(String recordId, MedicalHistory history) => _api.saveMedicalHistory(recordId, history);
  @override
  Future<PrescriptionValues> prescribe(String recordId, PrescriptionValues values) => _api.generatePrescription(recordId, values);
  @override
  Future<Appointment> complete(String appointmentId) async => (await _api.completeAppointment(appointmentId)).toEntity();
}
