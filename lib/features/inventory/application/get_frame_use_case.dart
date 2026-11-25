import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';

class GetFrameUseCase {
  const GetFrameUseCase({required this.repository});

  final CatalogRepository repository;

  Future<FrameItem> execute(String sku, {String? opticalStoreId}) => repository.frame(sku, opticalStoreId: opticalStoreId);
}
