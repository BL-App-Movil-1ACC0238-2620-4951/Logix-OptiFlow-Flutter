import 'package:logix_optiflow/features/searchbooking/domain/patient_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

class UpdatePatientProfileUseCase {
  const UpdatePatientProfileUseCase({required this.repository});

  final PatientRepository repository;

  Future<StaffPatient> execute(String patientId, {required String name, required String phone, DateTime? birthDate}) =>
      repository.updateProfile(patientId, name: name, phone: phone, birthDate: birthDate);
}
