import '../entities/appointment.dart';
import '../entities/clinical_record.dart';
import '../entities/staff_patient.dart';

abstract class ClinicalRepository {
  Future<StaffPatient> patient(String id);
  Future<List<Appointment>> appointments(String patientId);
  Future<List<ClinicalRecord>> records(String patientId);
  Future<ClinicalRecord> examine({required String patientId, required String appointmentId, required String observations});
  Future<ClinicalRecord> saveHistory(String recordId, MedicalHistory history);
  Future<PrescriptionValues> prescribe(String recordId, PrescriptionValues values);
  Future<Appointment> complete(String appointmentId);
}
