import 'package:logix_optiflow/features/clinical/domain/clinical_repository.dart';

class GetPatientsWithRecordsUseCase {
  const GetPatientsWithRecordsUseCase({required this.repository});

  final ClinicalRepository repository;

  Future<int> execute() => repository.patientsWithRecords();
}
