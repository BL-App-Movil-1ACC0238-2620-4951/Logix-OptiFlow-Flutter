import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';

/// Alta de un proveedor (`POST suppliers`); el contacto es opcional.
class RegisterSupplierUseCase {
  const RegisterSupplierUseCase({required this.repository});

  final InventoryRepository repository;

  Future<Supplier> execute(String name, String? contact) => repository.registerSupplier(name, contact);
}
