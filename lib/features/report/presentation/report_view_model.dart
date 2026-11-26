import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/inventory/application/get_low_stock_alerts_use_case.dart';
import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/report/application/get_monthly_report_use_case.dart';
import 'package:logix_optiflow/features/report/domain/staff_alert.dart';
import 'package:logix_optiflow/features/report/presentation/report_ui_state.dart';

/// Alertas y reportes del administrador.
class ReportViewModel extends ChangeNotifier {
  ReportViewModel({
    required this.session,
    required this.production,
    required this.getLowStockAlertsUseCase,
    required this.getMonthlyReportUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final ProductionViewModel production;
  final GetLowStockAlertsUseCase getLowStockAlertsUseCase;
  final GetMonthlyReportUseCase getMonthlyReportUseCase;

  ReportUiState _state = ReportUiState(month: _thisMonth());
  ReportUiState get state => _state;
  int _alertsRequest = 0;
  int _reportRequest = 0;

  static DateTime _thisMonth() {
    final today = StoreTime.today();
    return DateTime(today.year, today.month);
  }

  String? get _storeId {
    final id = session.session?.opticalStoreId;
    return id == null || id.isEmpty ? null : id;
  }

  void _emit(ReportUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _alertsRequest++;
    _reportRequest++;
    _emit(ReportUiState(month: _thisMonth()));
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;

  /// Stock bajo de la óptica, una alerta por orden atrasada y una si hay pedidos listos.
  List<StaffAlert> get alerts {
    final open = production.productionOrders.where((o) => o.stage != ProductionStage.delivered).toList();
    final ready = open.where((o) => o.stage == ProductionStage.ready).length;
    return [
      for (final item in _state.lowStock)
        StaffAlert(
          kind: 'Inventario', title: 'Stock bajo', action: 'Revisar stock', route: '/s/stock/${Uri.encodeComponent(item.sku)}',
          message: '${item.name} tiene ${item.quantity} ${item.quantity == 1 ? 'unidad' : 'unidades'} (mínimo ${item.minimumStock}).',
        ),
      for (final order in open.where((o) => o.needsAttention))
        StaffAlert(kind: 'Producción', title: 'Orden con retraso', action: 'Ver producción', route: '/s/production',
            message: '${order.code} de ${order.patient} está atrasada.'),
      if (ready > 0)
        StaffAlert(kind: 'Producción', title: 'Pedidos listos', action: 'Ver producción', route: '/s/production',
            message: ready == 1 ? '1 pedido espera ser entregado.' : '$ready pedidos esperan ser entregados.'),
    ];
  }

  Future<void> refreshAlerts() async {
    if (!session.canOpen('/s/alerts')) return;
    final current = session.session;
    final storeId = _storeId;
    final request = ++_alertsRequest;
    bool active() => identical(current, session.session) && request == _alertsRequest;
    _emit(_state.copyWith(alertsLoading: true, alertsError: () => null));
    final orders = production.refreshStaffOrders();
    try {
      if (storeId == null) throw ApiException('Tu cuenta no tiene una óptica asignada.');
      final loaded = await getLowStockAlertsUseCase.execute(storeId);
      if (active()) _state = _state.copyWith(lowStock: loaded);
    } catch (e) {
      if (active()) _state = _state.copyWith(alertsError: () => _message(e, 'No se pudieron cargar las alertas de stock.'));
    }
    await orders;
    if (active()) _emit(_state.copyWith(alertsLoading: false));
  }

  /// Cambia el mes del reporte; no deja pasar del mes actual.
  Future<void> changeMonth(int delta) async {
    final next = DateTime(_state.month.year, _state.month.month + delta);
    if (next.isAfter(_thisMonth())) return;
    _state = _state.copyWith(month: next);
    await refreshReport();
  }

  Future<void> refreshReport() async {
    if (!session.canOpen('/s/reports')) return;
    final current = session.session;
    final month = _state.month;
    final request = ++_reportRequest;
    bool active() => identical(current, session.session) && request == _reportRequest;
    _emit(_state.copyWith(reportLoading: true, reportError: () => null, report: () => null));
    try {
      final report = await getMonthlyReportUseCase.execute(month, _storeId);
      if (active()) _state = _state.copyWith(report: () => report);
    } catch (e) {
      if (active()) _state = _state.copyWith(reportError: () => _message(e, 'No se pudo cargar el reporte.'));
    } finally {
      if (active()) _emit(_state.copyWith(reportLoading: false));
    }
  }
}
