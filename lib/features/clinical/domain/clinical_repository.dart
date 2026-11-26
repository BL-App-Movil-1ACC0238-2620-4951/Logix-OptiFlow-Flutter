import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

abstract class ClinicalRepository {
  Future<StaffPatient> patient(String id);
  Future<List<Appointment>> appointments(String patientId);
  Future<List<ClinicalRecord>> records(String patientId);
  Future<ClinicalRecord> examine({required String patientId, required String appointmentId, required String observations});
  Future<ClinicalRecord> saveHistory(String recordId, MedicalHistory history);
  Future<PrescriptionValues> prescribe(String recordId, PrescriptionValues values);
  Future<PrescriptionValues> prescription(String recordId);
  Future<Appointment> complete(String appointmentId);
  Future<int> patientsWithRecords();
}
