import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

class GetWorkOrderUseCase {
  const GetWorkOrderUseCase({required this.repository});

  final ProductionRepository repository;

  Future<WorkOrderDetail> execute(String id) => repository.workOrder(id);
}
