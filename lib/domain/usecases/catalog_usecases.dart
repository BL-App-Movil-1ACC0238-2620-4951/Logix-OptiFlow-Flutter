import '../entities/frame.dart';
import '../repositories/catalog_repository.dart';

class GetFrames {
  const GetFrames(this._catalog);

  final CatalogRepository _catalog;

  Future<List<FrameItem>> call() => _catalog.frames();
}

class GetFrame {
  const GetFrame(this._catalog);

  final CatalogRepository _catalog;

  Future<FrameItem> call(String sku, {String? opticalStoreId}) => _catalog.frame(sku, opticalStoreId: opticalStoreId);
}

class UpdateFramePrice {
  const UpdateFramePrice(this._catalog);
  final CatalogRepository _catalog;
  Future<FrameItem> call(String sku, num price) => _catalog.updatePrice(sku, price);
}
