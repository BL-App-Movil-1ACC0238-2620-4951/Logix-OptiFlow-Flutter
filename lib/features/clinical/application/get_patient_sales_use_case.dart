import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';

class GetPatientSalesUseCase {
  const GetPatientSalesUseCase({required this.repository});

  final CommerceRepository repository;

  Future<List<Sale>> execute(String patientId) => repository.sales(patientId);
}
