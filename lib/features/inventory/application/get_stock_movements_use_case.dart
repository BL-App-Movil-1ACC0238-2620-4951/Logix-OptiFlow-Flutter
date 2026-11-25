import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

class GetStockMovementsUseCase {
  const GetStockMovementsUseCase({required this.repository});

  final InventoryRepository repository;

  Future<List<StockMovement>> execute({required String opticalStoreId, required DateTime from, required DateTime to, String? sku}) => repository.movements(opticalStoreId: opticalStoreId, from: from, to: to, sku: sku);
}
