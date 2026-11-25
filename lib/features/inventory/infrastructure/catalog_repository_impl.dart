import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_api.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl({required this.api});

  final InventoryApi api;

  @override
  Future<List<FrameItem>> frames() async => (await api.frameCatalog()).map((dto) => dto.toEntity()).toList();

  @override
  Future<FrameItem> frame(String sku, {String? opticalStoreId}) async => (await api.frameModel(sku, opticalStoreId: opticalStoreId)).toEntity();

  @override
  Future<FrameItem> updatePrice(String sku, num price) async => (await api.updateFramePrice(sku, price)).toEntity();
}
