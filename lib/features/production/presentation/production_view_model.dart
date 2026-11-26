import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/production/application/get_production_orders_use_case.dart';
import 'package:logix_optiflow/features/production/application/get_staff_orders_use_case.dart';
import 'package:logix_optiflow/features/production/presentation/production_ui_state.dart';

/// Órdenes de trabajo de la óptica.
class ProductionViewModel extends ChangeNotifier {
  ProductionViewModel({required this.session, required this.getStaffOrdersUseCase, required this.getProductionOrdersUseCase}) {
    session.addLogoutListener(_reset);
    _state = ProductionUiState(productionOrders: getProductionOrdersUseCase.execute());
  }

  final SessionViewModel session;
  final GetStaffOrdersUseCase getStaffOrdersUseCase;
  final GetProductionOrdersUseCase getProductionOrdersUseCase;

  late ProductionUiState _state;
  ProductionUiState get state => _state;
  int _request = 0;

  void _emit(ProductionUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _request++;
    _emit(ProductionUiState(productionOrders: _state.productionOrders));
  }

  /// Pacientes con una orden que aún no se entrega.
  Set<String> get workshopPatientIds =>
      _state.orders.where((o) => o.status != 'DELIVERED').map((o) => o.patientId).whereType<String>().toSet();

  Future<void> refreshStaffOrders() async {
    if (!session.canOpen('/s/production')) return;
    final current = session.session;
    final request = ++_request;
    bool active() => identical(current, session.session) && request == _request;
    _emit(_state.copyWith(loading: true, error: () => null));
    try {
      final loaded = await getStaffOrdersUseCase.execute();
      if (active()) _state = _state.copyWith(orders: loaded);
    } catch (e) {
      if (active()) _state = _state.copyWith(error: () => e is ApiException ? e.message : 'No se pudieron cargar las órdenes.');
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }
}
