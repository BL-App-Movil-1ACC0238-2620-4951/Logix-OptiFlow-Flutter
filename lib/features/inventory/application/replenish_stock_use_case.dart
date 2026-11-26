import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

class ReplenishStockUseCase {
  const ReplenishStockUseCase({required this.repository});

  final InventoryRepository repository;

  Future<StockMovement> execute({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock}) => repository.replenish(opticalStoreId: opticalStoreId, sku: sku, supplierId: supplierId, quantity: quantity, minimumStock: minimumStock);
}
