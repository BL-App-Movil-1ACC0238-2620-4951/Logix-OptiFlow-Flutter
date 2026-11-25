import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

class GetStoreStockUseCase {
  const GetStoreStockUseCase({required this.repository});

  final InventoryRepository repository;

  Future<StoreInventory> execute(String opticalStoreId) => repository.stock(opticalStoreId);
}
