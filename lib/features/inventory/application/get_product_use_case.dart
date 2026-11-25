import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';

class GetProductUseCase {
  const GetProductUseCase({required this.repository});

  final InventoryRepository repository;

  ProductItem execute(String id) => repository.product(id);
}
