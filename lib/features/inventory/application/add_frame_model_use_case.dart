import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

/// Unidades con las que entra una montura nueva a una óptica.
class InitialStock {
  const InitialStock({required this.opticalStoreId, required this.supplierId, required this.quantity, this.minimumStock});
  final String opticalStoreId;
  final String supplierId;
  final int quantity;
  final int? minimumStock;
}

/// La montura se creó, pero su stock inicial no se pudo registrar.
class InitialStockFailed implements Exception {
  const InitialStockFailed(this.frame, this.cause);
  final FrameItem frame;
  final Object cause;
}

/// Registra una montura en el catálogo (`POST inventory/frames`) y, si se indica, la ingresa al stock
/// de la óptica con una reposición (`POST inventory/replenishments`).
class AddFrameModelUseCase {
  const AddFrameModelUseCase({required this.catalog, required this.inventory});

  final CatalogRepository catalog;
  final InventoryRepository inventory;

  Future<FrameItem> execute({
    required String sku,
    required String name,
    String? material,
    String? shape,
    String? color,
    required num price,
    InitialStock? initialStock,
  }) async {
    final frame = await catalog.addFrame(sku: sku, name: name, material: material, shape: shape, color: color, price: price);
    if (initialStock != null) {
      try {
        await inventory.replenish(
          opticalStoreId: initialStock.opticalStoreId,
          sku: frame.sku,
          supplierId: initialStock.supplierId,
          quantity: initialStock.quantity,
          minimumStock: initialStock.minimumStock,
        );
      } catch (e) {
        throw InitialStockFailed(frame, e);
      }
    }
    return frame;
  }
}
