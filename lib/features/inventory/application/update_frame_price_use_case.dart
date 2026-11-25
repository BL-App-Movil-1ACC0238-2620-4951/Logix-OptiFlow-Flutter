import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';

class UpdateFramePriceUseCase {
  const UpdateFramePriceUseCase({required this.repository});

  final CatalogRepository repository;

  Future<FrameItem> execute(String sku, num price) => repository.updatePrice(sku, price);
}
