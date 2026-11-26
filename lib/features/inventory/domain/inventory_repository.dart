import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';

abstract class InventoryRepository {
  Future<StoreInventory> stock(String opticalStoreId);
  Future<List<Supplier>> suppliers();
  Future<List<StockMovement>> movements({required String opticalStoreId, required DateTime from, required DateTime to, String? sku});
  Future<StockMovement> replenish({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock});
  List<ProductItem> products();
  ProductItem product(String id);
}
