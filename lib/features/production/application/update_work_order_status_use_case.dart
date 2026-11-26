import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

class UpdateWorkOrderStatusUseCase {
  const UpdateWorkOrderStatusUseCase({required this.repository});

  final ProductionRepository repository;

  Future<WorkOrderDetail> execute(String id, String status) => repository.updateStatus(id, status);
}
