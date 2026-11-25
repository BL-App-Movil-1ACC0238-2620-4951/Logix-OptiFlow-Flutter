import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/production/application/get_staff_orders_use_case.dart';
import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/presentation/production_ui_state.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patient_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/presentation/mappers/staff_view_mapper.dart';

/// Órdenes de trabajo de la óptica y su tablero por etapa.
class ProductionViewModel extends ChangeNotifier {
  ProductionViewModel({
    required this.session,
    required this.patients,
    required this.getStaffOrdersUseCase,
    required this.getStaffPatientUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final StaffPatientsViewModel patients;
  final GetStaffOrdersUseCase getStaffOrdersUseCase;
  final GetStaffPatientUseCase getStaffPatientUseCase;

  ProductionUiState _state = const ProductionUiState();
  ProductionUiState get state => _state;
  int _request = 0;

  void _emit(ProductionUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _request++;
    _emit(const ProductionUiState());
  }

  /// Pacientes con una orden que aún no se entrega.
  Set<String> get workshopPatientIds =>
      _state.orders.where((o) => o.status != 'DELIVERED').map((o) => o.patientId).whereType<String>().toSet();

  /// Tablero de producción armado con las órdenes reales.
  List<ProductionOrder> get productionOrders => [
        for (final order in _state.orders)
          StaffViewMapper.productionOrder(order, _state.patientNames[order.patientId] ?? 'Paciente'),
      ];

  Future<void> refreshStaffOrders() async {
    if (!session.canOpen('/s/production')) return;
    final current = session.session;
    final request = ++_request;
    bool active() => identical(current, session.session) && request == _request;
    _emit(_state.copyWith(loading: true, error: () => null));
    try {
      final loaded = await getStaffOrdersUseCase.execute();
      if (!active()) return;
      final names = Map.of(_state.patientNames);
      final missing = loaded.map((o) => o.patientId).whereType<String>().where((id) => !names.containsKey(id)).toSet();
      await Future.wait(missing.map((id) async {
        var patient = patients.staffPatient(id);
        if (patient == null) { try { patient = await getStaffPatientUseCase.execute(id); } catch (_) {} }
        if (patient != null) names[id] = patient.fullName;
      }));
      if (active()) _state = _state.copyWith(orders: loaded, patientNames: names);
    } catch (e) {
      if (active()) _state = _state.copyWith(error: () => e is ApiException ? e.message : 'No se pudieron cargar las órdenes.');
    } finally {
      if (active()) _emit(_state.copyWith(loading: false));
    }
  }
}
