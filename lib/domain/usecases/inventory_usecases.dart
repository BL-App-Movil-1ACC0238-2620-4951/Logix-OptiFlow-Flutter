import '../entities/inventory.dart';
import '../repositories/inventory_repository.dart';

class GetStoreStock {
  const GetStoreStock(this._inventory);
  final InventoryRepository _inventory;
  Future<StoreInventory> call(String opticalStoreId) => _inventory.stock(opticalStoreId);
}

class GetSuppliers {
  const GetSuppliers(this._inventory);
  final InventoryRepository _inventory;
  Future<List<Supplier>> call() => _inventory.suppliers();
}

class GetStockMovements {
  const GetStockMovements(this._inventory);
  final InventoryRepository _inventory;
  Future<List<StockMovement>> call({required String opticalStoreId, required DateTime from, required DateTime to, String? sku}) =>
      _inventory.movements(opticalStoreId: opticalStoreId, from: from, to: to, sku: sku);
}

class ReplenishStock {
  const ReplenishStock(this._inventory);
  final InventoryRepository _inventory;
  Future<StockMovement> call({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock}) =>
      _inventory.replenish(opticalStoreId: opticalStoreId, sku: sku, supplierId: supplierId, quantity: quantity, minimumStock: minimumStock);
}
