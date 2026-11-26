import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_repository.dart';

class GetPrescriptionUseCase {
  const GetPrescriptionUseCase({required this.repository});

  final ClinicalRepository repository;

  Future<PrescriptionValues> execute(String recordId) => repository.prescription(recordId);
}
