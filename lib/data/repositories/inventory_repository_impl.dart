import '../../domain/entities/inventory.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/optiflow_api.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._api);
  final OptiFlowApi _api;

  @override
  Future<StoreInventory> stock(String opticalStoreId) => _api.inventoryStock(opticalStoreId);
  @override
  Future<List<Supplier>> suppliers() => _api.suppliers();
  @override
  Future<List<StockMovement>> movements({required String opticalStoreId, required DateTime from, required DateTime to, String? sku}) =>
      _api.stockMovements(opticalStoreId: opticalStoreId, from: from, to: to, sku: sku);
  @override
  Future<StockMovement> replenish({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock}) =>
      _api.replenishStock(opticalStoreId: opticalStoreId, sku: sku, supplierId: supplierId, quantity: quantity, minimumStock: minimumStock);
}
