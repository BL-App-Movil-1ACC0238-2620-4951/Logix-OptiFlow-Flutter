import 'package:logix_optiflow/features/searchbooking/domain/patient_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

class GetStaffPatientsUseCase {
  const GetStaffPatientsUseCase({required this.repository});

  final PatientRepository repository;

  Future<List<StaffPatient>> execute() => repository.patients();
}
