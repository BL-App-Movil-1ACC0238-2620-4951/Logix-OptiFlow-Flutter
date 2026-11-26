import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

class NotifyDeliveryDelayUseCase {
  const NotifyDeliveryDelayUseCase({required this.repository});

  final ProductionRepository repository;

  Future<WorkOrderDetail> execute(String id, String reason, String newEstimatedDeliveryDate) =>
      repository.notifyDelay(id, reason, newEstimatedDeliveryDate);
}
