import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_repository.dart';

class GetPatientClinicalRecordsUseCase {
  const GetPatientClinicalRecordsUseCase({required this.repository});

  final ClinicalRepository repository;

  Future<List<ClinicalRecord>> execute(String patientId) => repository.records(patientId);
}
