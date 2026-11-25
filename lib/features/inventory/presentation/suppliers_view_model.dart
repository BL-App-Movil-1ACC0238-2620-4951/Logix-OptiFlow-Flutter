import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/inventory/application/get_suppliers_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/register_supplier_use_case.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';

class SuppliersUiState {
  const SuppliersUiState({
    this.loading = true,
    this.suppliers = const [],
    this.saving = false,
    this.message,
    this.error,
  });

  final bool loading;
  final List<Supplier> suppliers;
  final bool saving;
  final String? message;
  final String? error;

  SuppliersUiState copyWith({
    bool? loading,
    List<Supplier>? suppliers,
    bool? saving,
    ValueGetter<String?>? message,
    ValueGetter<String?>? error,
  }) {
    return SuppliersUiState(
      loading: loading ?? this.loading,
      suppliers: suppliers ?? this.suppliers,
      saving: saving ?? this.saving,
      message: message != null ? message() : this.message,
      error: error != null ? error() : this.error,
    );
  }
}

/// Proveedores del inventario: lista y alta (`GET` y `POST suppliers`).
class SuppliersViewModel extends ChangeNotifier {
  SuppliersViewModel({required this.getSuppliersUseCase, required this.registerSupplierUseCase});

  final GetSuppliersUseCase getSuppliersUseCase;
  final RegisterSupplierUseCase registerSupplierUseCase;

  SuppliersUiState _state = const SuppliersUiState();
  SuppliersUiState get state => _state;
  bool _disposed = false;

  void _emit(SuppliersUiState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    try {
      final list = await getSuppliersUseCase.execute();
      _emit(_state.copyWith(loading: false, suppliers: list));
    } catch (e) {
      _emit(_state.copyWith(loading: false, error: () => _message(e, 'No se pudieron cargar los proveedores.')));
    }
  }

  /// Registra el proveedor; devuelve true si se guardó, para que la pantalla limpie el formulario.
  Future<bool> register(String name, String contact) async {
    if (name.trim().isEmpty) {
      _emit(_state.copyWith(error: () => 'Escribe el nombre del proveedor.'));
      return false;
    }
    if (_state.saving) return false;
    _emit(_state.copyWith(saving: true, error: () => null, message: () => null));
    try {
      final added = await registerSupplierUseCase.execute(name.trim(), contact.trim().isEmpty ? null : contact.trim());
      final suppliers = [..._state.suppliers, added]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _emit(_state.copyWith(saving: false, suppliers: suppliers, message: () => 'Proveedor ${added.name} registrado.'));
      return true;
    } catch (e) {
      _emit(_state.copyWith(saving: false, error: () => _message(e, 'No se pudo registrar el proveedor.')));
      return false;
    }
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;
}
