import '../../domain/entities/frame.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/optiflow_api.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._api);
  final OptiFlowApi _api;

  @override
  Future<List<FrameItem>> frames() async => (await _api.frameCatalog()).map((dto) => dto.toEntity()).toList();

  @override
  Future<FrameItem> frame(String sku, {String? opticalStoreId}) async => (await _api.frameModel(sku, opticalStoreId: opticalStoreId)).toEntity();

  @override
  Future<FrameItem> updatePrice(String sku, num price) async => (await _api.updateFramePrice(sku, price)).toEntity();
}
