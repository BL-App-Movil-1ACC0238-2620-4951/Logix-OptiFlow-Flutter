import 'package:logix_optiflow/features/searchbooking/domain/patient_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

class RegisterPatientByStaffUseCase {
  const RegisterPatientByStaffUseCase({required this.repository});

  final PatientRepository repository;

  Future<StaffPatient> execute({required String name, required String email, required String phone, required String dni, DateTime? birthDate}) => repository.registerPatient(name: name, email: email, phone: phone, dni: dni, birthDate: birthDate);
}
