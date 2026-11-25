import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/frame_stock.dart';
import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

/// Ópticas que tienen la montura en stock, consultando cada una en paralelo.
class GetFrameStockUseCase {
  const GetFrameStockUseCase({required this.stores, required this.catalog});

  final StoreRepository stores;
  final CatalogRepository catalog;

  Future<List<FrameStock>> execute(String sku) async {
    final all = await stores.list();
    final found = await Future.wait(all.map((store) async {
      try {
        final quantity = (await catalog.frame(sku, opticalStoreId: store.id)).stock;
        return quantity > 0 ? FrameStock(store: store, quantity: quantity) : null;
      } catch (_) {
        return null;
      }
    }));
    return found.whereType<FrameStock>().toList();
  }
}
