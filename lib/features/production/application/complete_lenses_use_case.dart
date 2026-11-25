import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

class CompleteLensesUseCase {
  const CompleteLensesUseCase({required this.repository});

  final ProductionRepository repository;

  /// Sin `lensIds` se marcan todos los lentes.
  Future<WorkOrderDetail> execute(String id, [List<String>? lensIds]) => repository.completeLenses(id, lensIds);
}
