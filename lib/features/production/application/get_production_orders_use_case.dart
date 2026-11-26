import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/domain/production_repository.dart';

class GetProductionOrdersUseCase {
  const GetProductionOrdersUseCase({required this.repository});

  final ProductionRepository repository;

  List<ProductionOrder> execute() => repository.productionOrders();
}
