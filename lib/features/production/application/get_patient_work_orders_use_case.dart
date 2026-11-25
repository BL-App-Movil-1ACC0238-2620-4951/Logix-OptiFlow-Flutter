import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';

class GetPatientWorkOrdersUseCase {
  const GetPatientWorkOrdersUseCase({required this.repository});

  final ProductionRepository repository;

  Future<List<WorkOrder>> execute(String patientId) => repository.patientWorkOrders(patientId);
}
