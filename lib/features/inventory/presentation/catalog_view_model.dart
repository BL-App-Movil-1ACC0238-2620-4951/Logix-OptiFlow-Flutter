import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/inventory/application/get_frame_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_frames_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_stock_movements_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_store_stock_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_suppliers_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/replenish_stock_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/update_frame_price_use_case.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_ui_state.dart';

/// Catálogo de monturas del paciente e inventario, proveedores y movimientos del personal.
class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel({
    required this.session,
    required this.getFramesUseCase,
    required this.getFrameUseCase,
    required this.updateFramePriceUseCase,
    required this.getStoreStockUseCase,
    required this.getSuppliersUseCase,
    required this.getStockMovementsUseCase,
    required this.replenishStockUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final GetFramesUseCase getFramesUseCase;
  final GetFrameUseCase getFrameUseCase;
  final UpdateFramePriceUseCase updateFramePriceUseCase;
  final GetStoreStockUseCase getStoreStockUseCase;
  final GetSuppliersUseCase getSuppliersUseCase;
  final GetStockMovementsUseCase getStockMovementsUseCase;
  final ReplenishStockUseCase replenishStockUseCase;

  CatalogUiState _state = const CatalogUiState();
  CatalogUiState get state => _state;
  int _catalogRequest = 0;
  int _inventoryRequest = 0;
  int _supplierRequest = 0;
  int _movementsRequest = 0;
  final Map<String, int> _frameRequests = {};

  PatientSession? get _current => session.session;

  void _emit(CatalogUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _catalogRequest++;
    _inventoryRequest++;
    _supplierRequest++;
    _movementsRequest++;
    for (final sku in _frameRequests.keys.toList()) { _frameRequests[sku] = _frameRequests[sku]! + 1; }
    _emit(const CatalogUiState());
  }

  bool get canUseCatalog {
    final current = _current;
    return current?.isAuthenticated == true && (current!.isPatient || current.role.can(StaffFeature.catalog));
  }

  FrameItem? frameById(String sku) => _state.framesBySku[sku];
  ProductItem? productById(String sku) => _state.productsBySku[sku];
  int stockOf(ProductItem product) => product.available;

  /// Limpia el error de la última operación sin avisar a la vista.
  void clearMutationError() {
    _state = _state.copyWith(mutationError: () => null);
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;

  CatalogUiState _withFrame(CatalogUiState state, FrameItem frame) => state.copyWith(
        framesBySku: {...state.framesBySku, frame.id: frame},
        frames: [for (final item in state.frames) item.id == frame.id ? frame : item],
      );

  ProductItem _product(FrameItem frame, {StockLevel? stock, bool storeStockLoaded = false}) => ProductItem(
    id: frame.id, sku: frame.sku, name: frame.name, code: frame.sku,
    detail: frame.description, price: frame.fromPrice, tag: frame.category,
    available: stock?.quantity ?? frame.stock, quantityKnown: storeStockLoaded || stock != null || frame.stockKnown,
    minimumStock: stock?.minimumStock ?? frame.minimumStock,
    image: frame.image, category: frame.category, size: '', location: '', supplier: '',
  );

  Future<void> refreshCatalog() async {
    if (!canUseCatalog) return;
    final current = _current;
    final request = ++_catalogRequest;
    bool active() => identical(current, _current) && request == _catalogRequest;
    _emit(_state.copyWith(catalogLoading: true, catalogError: () => null));
    try {
      final loaded = await getFramesUseCase.execute();
      if (!active()) return;
      _state = _state.copyWith(frames: loaded, framesBySku: {..._state.framesBySku, for (final frame in loaded) frame.id: frame});
    } catch (e) {
      if (active()) _state = _state.copyWith(catalogError: () => _message(e, 'No se pudo cargar el catálogo.'));
    } finally {
      if (active()) _emit(_state.copyWith(catalogLoading: false));
    }
  }

  Future<FrameItem?> loadFrame(String sku, {bool forInventory = false}) async {
    if (!canUseCatalog || _state.frameLoading.contains(sku)) return frameById(sku);
    final current = _current;
    final storeId = forInventory ? current?.opticalStoreId : null;
    if (forInventory && (storeId == null || storeId.isEmpty)) {
      _emit(_state.copyWith(frameErrors: {..._state.frameErrors, sku: 'Tu cuenta no tiene una óptica asignada.'}));
      return null;
    }
    final request = (_frameRequests[sku] ?? 0) + 1;
    _frameRequests[sku] = request;
    bool active() => identical(current, _current) && _frameRequests[sku] == request;
    _emit(_state.copyWith(
      frameLoading: {..._state.frameLoading, sku},
      frameErrors: Map.of(_state.frameErrors)..remove(sku),
    ));
    try {
      final frame = await getFrameUseCase.execute(sku, opticalStoreId: storeId);
      if (!active()) return null;
      _state = _withFrame(_state, frame);
      if (forInventory) _state = _state.copyWith(productsBySku: {..._state.productsBySku, sku: _product(frame)});
      return frame;
    } catch (e) {
      if (active()) {
        _state = _state.copyWith(frameErrors: {..._state.frameErrors, sku: _message(e, 'No se encontró la montura o no se pudo cargar.')});
      }
      return null;
    } finally {
      if (active()) _emit(_state.copyWith(frameLoading: {..._state.frameLoading}..remove(sku)));
    }
  }

  Future<void> refreshInventory() async {
    final current = _current;
    if (!session.canOpen('/s/inventory')) return;
    final storeId = current?.opticalStoreId;
    if (storeId == null || storeId.isEmpty) {
      _emit(_state.copyWith(inventoryError: () => 'Tu cuenta no tiene una óptica asignada. Solicita la asignación al administrador.'));
      return;
    }
    final request = ++_inventoryRequest;
    bool active() => identical(current, _current) && request == _inventoryRequest;
    _emit(_state.copyWith(inventoryLoading: true, inventoryError: () => null));
    try {
      final results = await Future.wait<Object>([getFramesUseCase.execute(), getStoreStockUseCase.execute(storeId)]);
      if (!active()) return;
      final catalog = results[0] as List<FrameItem>;
      final inventory = results[1] as StoreInventory;
      if (inventory.opticalStoreId != storeId) throw ApiException('El stock recibido pertenece a otra óptica.');
      final stocks = {for (final stock in inventory.stocks) stock.sku: stock};
      final products = [for (final frame in catalog) _product(frame, stock: stocks[frame.sku], storeStockLoaded: true)];
      var next = _state.copyWith(products: products, productsBySku: {for (final product in products) product.id: product});
      for (final frame in catalog) { next = _withFrame(next, frame); }
      _state = next;
    } catch (e) {
      if (active()) _state = _state.copyWith(inventoryError: () => _message(e, 'No se pudo cargar el inventario de tu óptica.'));
    } finally {
      if (active()) _emit(_state.copyWith(inventoryLoading: false));
    }
  }

  Future<void> refreshSuppliers() async {
    if (!session.canOpen('/s/movement')) return;
    final current = _current;
    final request = ++_supplierRequest;
    bool active() => identical(current, _current) && request == _supplierRequest;
    _emit(_state.copyWith(suppliersLoading: true, suppliersError: () => null));
    try {
      final loaded = await getSuppliersUseCase.execute();
      if (active()) _state = _state.copyWith(suppliers: loaded);
    } catch (e) {
      if (active()) _state = _state.copyWith(suppliersError: () => _message(e, 'No se pudieron cargar los proveedores.'));
    } finally {
      if (active()) _emit(_state.copyWith(suppliersLoading: false));
    }
  }

  Future<void> refreshStockMovements({String? sku, DateTime? from, DateTime? to}) async {
    if (!session.canOpen('/s/movement')) return;
    final current = _current;
    final storeId = current?.opticalStoreId;
    if (storeId == null || storeId.isEmpty) {
      _emit(_state.copyWith(movementsError: () => 'Tu cuenta no tiene una óptica asignada.'));
      return;
    }
    final request = ++_movementsRequest;
    bool active() => identical(current, _current) && request == _movementsRequest;
    _emit(_state.copyWith(movementsLoading: true, movementsError: () => null, movements: const []));
    try {
      final end = to ?? DateTime.now();
      final loaded = await getStockMovementsUseCase.execute(opticalStoreId: storeId, from: from ?? end.subtract(const Duration(days: 30)), to: end, sku: sku);
      if (active()) _state = _state.copyWith(movements: loaded);
    } catch (e) {
      if (active()) _state = _state.copyWith(movementsError: () => _message(e, 'No se pudieron cargar los movimientos.'));
    } finally {
      if (active()) _emit(_state.copyWith(movementsLoading: false));
    }
  }

  Future<bool> replenishStock({required String sku, required String supplierId, required int quantity, int? minimumStock}) async {
    if (_state.mutationBusy) return false;
    final current = _current;
    final storeId = current?.opticalStoreId;
    String? error;
    if (!session.canOpen('/s/movement') || storeId == null || storeId.isEmpty) {
      error = 'Solo el administrador con óptica asignada puede registrar ingresos.';
    } else if (sku.trim().isEmpty || supplierId.isEmpty || quantity < 1 || quantity > 1000 || (minimumStock != null && minimumStock < 0)) {
      error = 'Elige montura y proveedor, cantidad de 1 a 1000 y mínimo mayor o igual a cero.';
    }
    if (error != null) {
      _emit(_state.copyWith(mutationError: () => error));
      return false;
    }
    _emit(_state.copyWith(mutationBusy: true, mutationError: () => null));
    try {
      await replenishStockUseCase.execute(opticalStoreId: storeId!, sku: sku.trim(), supplierId: supplierId, quantity: quantity, minimumStock: minimumStock);
      if (!identical(current, _current)) return false;
      _inventoryRequest++;
      _frameRequests[sku] = (_frameRequests[sku] ?? 0) + 1;
      _state = _state.copyWith(frameLoading: {..._state.frameLoading}..remove(sku));
      // The movement is already saved. A reload error must not invite a duplicate POST.
      await refreshInventory();
      await loadFrame(sku, forInventory: true);
      return identical(current, _current);
    } catch (e) {
      if (identical(current, _current)) {
        _state = _state.copyWith(mutationError: () => _message(e, 'No se pudo verificar el ingreso. Consulta los movimientos antes de reintentar.'));
      }
      return false;
    } finally {
      if (identical(current, _current)) _emit(_state.copyWith(mutationBusy: false));
    }
  }

  Future<bool> updateFramePrice(String sku, num price) async {
    if (_state.mutationBusy) return false;
    final current = _current;
    if (!canUseCatalog || current!.isPatient || !current.role.can(StaffFeature.catalog) || !price.isFinite || price <= 0 || price > 99999999.99 || (price * 100 - (price * 100).round()).abs() > 0.000001) {
      _emit(_state.copyWith(mutationError: () => 'Ingresa un precio válido, mayor a cero, con máximo dos decimales.'));
      return false;
    }
    _emit(_state.copyWith(mutationBusy: true, mutationError: () => null));
    try {
      final updated = await updateFramePriceUseCase.execute(sku, price);
      if (!identical(current, _current)) return false;
      _catalogRequest++;
      _inventoryRequest++;
      _frameRequests[sku] = (_frameRequests[sku] ?? 0) + 1;
      final old = _state.productsBySku[sku];
      final product = old?.withPrice(updated.fromPrice) ?? _product(updated);
      _state = _withFrame(_state, updated).copyWith(
        catalogLoading: false,
        inventoryLoading: false,
        frameLoading: {..._state.frameLoading}..remove(sku),
        productsBySku: {..._state.productsBySku, sku: product},
        products: [for (final item in _state.products) item.id == sku ? product : item],
      );
      return true;
    } catch (e) {
      if (identical(current, _current)) _state = _state.copyWith(mutationError: () => _message(e, 'No se pudo actualizar el precio.'));
      return false;
    } finally {
      if (identical(current, _current)) _emit(_state.copyWith(mutationBusy: false));
    }
  }
}
