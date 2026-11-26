import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';

class GetProductsUseCase {
  const GetProductsUseCase({required this.repository});

  final InventoryRepository repository;

  List<ProductItem> execute() => repository.products();
}
