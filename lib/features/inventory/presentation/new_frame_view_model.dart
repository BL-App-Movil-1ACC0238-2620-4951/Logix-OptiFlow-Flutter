import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/inventory/application/add_frame_model_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_suppliers_use_case.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';

/// El backend acepta de 1 a 1000 unidades por reposición.
const maxReplenishment = 1000;

class NewFrameUiState {
  const NewFrameUiState({
    this.withStock = false,
    this.suppliers = const [],
    this.supplierId,
    this.saving = false,
    this.error,
    this.createdSku,
  });

  /// Solo el admin puede reponer; el asesor crea la montura sin stock.
  final bool withStock;
  final List<Supplier> suppliers;
  final String? supplierId;
  final bool saving;
  final String? error;
  /// SKU creado; la pantalla abre su detalle.
  final String? createdSku;

  Supplier? get supplier => suppliers.where((s) => s.id == supplierId).firstOrNull;

  NewFrameUiState copyWith({
    bool? withStock,
    List<Supplier>? suppliers,
    ValueGetter<String?>? supplierId,
    bool? saving,
    ValueGetter<String?>? error,
    ValueGetter<String?>? createdSku,
  }) {
    return NewFrameUiState(
      withStock: withStock ?? this.withStock,
      suppliers: suppliers ?? this.suppliers,
      supplierId: supplierId != null ? supplierId() : this.supplierId,
      saving: saving ?? this.saving,
      error: error != null ? error() : this.error,
      createdSku: createdSku != null ? createdSku() : this.createdSku,
    );
  }
}

/// Alta de una montura en el catálogo (`POST inventory/frames`) y, para el admin, su stock inicial.
class NewFrameViewModel extends ChangeNotifier {
  NewFrameViewModel({required this.session, required this.catalog, required this.addFrameModelUseCase, required this.getSuppliersUseCase});

  final SessionViewModel session;
  final CatalogViewModel catalog;
  final AddFrameModelUseCase addFrameModelUseCase;
  final GetSuppliersUseCase getSuppliersUseCase;

  NewFrameUiState _state = const NewFrameUiState();
  NewFrameUiState get state => _state;
  bool _disposed = false;

  void _emit(NewFrameUiState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (!session.canOpen('/s/movement')) return;
    _emit(_state.copyWith(withStock: true));
    try {
      final list = await getSuppliersUseCase.execute();
      _emit(_state.copyWith(suppliers: list, supplierId: () => list.firstOrNull?.id));
    } catch (_) {}
  }

  void selectSupplier(String id) => _emit(_state.copyWith(supplierId: () => id));

  Future<void> submit({
    required String sku,
    required String name,
    required String material,
    required String shape,
    required String color,
    required String price,
    required String quantity,
    required String minimum,
  }) async {
    if (_state.saving) return;
    final value = num.tryParse(price.trim());
    final error = sku.trim().isEmpty
        ? 'Escribe el SKU de la montura.'
        : name.trim().isEmpty
            ? 'Escribe el nombre de la montura.'
            : value == null || value <= 0
                ? 'Escribe un precio mayor que cero.'
                : null;
    if (error != null) {
      _emit(_state.copyWith(error: () => error));
      return;
    }
    final units = int.tryParse(quantity.trim()) ?? 0;
    final storeId = session.session?.opticalStoreId;
    final supplierId = _state.supplierId;
    if (_state.withStock && units > maxReplenishment) {
      _emit(_state.copyWith(error: () => 'Se pueden ingresar hasta $maxReplenishment unidades.'));
      return;
    }
    final needsStock = _state.withStock && units > 0;
    if (needsStock && (supplierId == null || storeId == null || storeId.isEmpty)) {
      _emit(_state.copyWith(error: () => 'Elige el proveedor de las unidades.'));
      return;
    }
    final initial = needsStock
        ? InitialStock(opticalStoreId: storeId!, supplierId: supplierId!, quantity: units, minimumStock: int.tryParse(minimum.trim()))
        : null;
    String? blankToNull(String v) => v.trim().isEmpty ? null : v.trim();
    _emit(_state.copyWith(saving: true, error: () => null));
    try {
      final frame = await addFrameModelUseCase.execute(
        sku: sku.trim(),
        name: name.trim(),
        material: blankToNull(material),
        shape: blankToNull(shape),
        color: blankToNull(color),
        price: value!,
        initialStock: initial,
      );
      _emit(_state.copyWith(saving: false, createdSku: () => frame.sku));
    } on InitialStockFailed catch (e) {
      // La montura ya existe; se abre su detalle y el stock se ingresa desde ahí.
      final reason = e.cause is ApiException ? (e.cause as ApiException).message : '';
      _emit(_state.copyWith(saving: false, createdSku: () => e.frame.sku, error: () => 'La montura se creó, pero no se ingresó su stock. $reason'.trim()));
    } catch (e) {
      _emit(_state.copyWith(saving: false, error: () => e is ApiException ? e.message : 'No se pudo registrar la montura.'));
      return;
    }
    catalog.refreshInventory();
  }
}
