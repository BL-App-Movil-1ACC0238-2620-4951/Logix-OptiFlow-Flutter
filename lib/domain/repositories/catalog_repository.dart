import '../entities/frame.dart';

abstract class CatalogRepository {
  Future<List<FrameItem>> frames();

  Future<FrameItem> frame(String sku, {String? opticalStoreId});

  Future<FrameItem> updatePrice(String sku, num price);
}
