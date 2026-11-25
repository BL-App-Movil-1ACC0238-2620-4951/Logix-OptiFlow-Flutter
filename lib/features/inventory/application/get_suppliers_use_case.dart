import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

class GetSuppliersUseCase {
  const GetSuppliersUseCase({required this.repository});

  final InventoryRepository repository;

  Future<List<Supplier>> execute() => repository.suppliers();
}
