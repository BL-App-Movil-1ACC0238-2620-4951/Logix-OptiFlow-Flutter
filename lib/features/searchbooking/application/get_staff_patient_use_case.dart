import 'package:logix_optiflow/features/searchbooking/domain/patient_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

class GetStaffPatientUseCase {
  const GetStaffPatientUseCase({required this.repository});

  final PatientRepository repository;

  Future<StaffPatient> execute(String id) => repository.patient(id);
}
