import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

class GetLowStockAlertsUseCase {
  const GetLowStockAlertsUseCase({required this.repository});

  final InventoryRepository repository;

  Future<List<LowStockAlert>> execute(String opticalStoreId) => repository.lowStockAlerts(opticalStoreId);
}
