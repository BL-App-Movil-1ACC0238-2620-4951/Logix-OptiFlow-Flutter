import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

/// Pacientes que ve el personal de la óptica.
abstract class PatientRepository {
  Future<List<StaffPatient>> patients();
  Future<StaffPatient> patient(String id);
  Future<StaffPatient> updateProfile(String id, {required String name, required String phone, DateTime? birthDate});
  Future<StaffPatient> registerPatient({required String name, required String email, required String phone, required String dni, DateTime? birthDate});
}
