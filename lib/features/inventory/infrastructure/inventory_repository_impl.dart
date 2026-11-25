import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_api.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_local_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl({required this.api});

  final InventoryApi api;

  @override
  Future<StoreInventory> stock(String opticalStoreId) => api.inventoryStock(opticalStoreId);
  @override
  Future<List<Supplier>> suppliers() => api.suppliers();
  @override
  Future<List<StockMovement>> movements({required String opticalStoreId, required DateTime from, required DateTime to, String? sku}) =>
      api.stockMovements(opticalStoreId: opticalStoreId, from: from, to: to, sku: sku);
  @override
  Future<StockMovement> replenish({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock}) =>
      api.replenishStock(opticalStoreId: opticalStoreId, sku: sku, supplierId: supplierId, quantity: quantity, minimumStock: minimumStock);
  @override
  List<ProductItem> products() => InventoryLocalDataSource.products;
  @override
  ProductItem product(String id) => InventoryLocalDataSource.product(id);
}
