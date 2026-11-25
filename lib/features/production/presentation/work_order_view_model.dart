import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/production/application/assign_technician_use_case.dart';
import 'package:logix_optiflow/features/production/application/complete_lenses_use_case.dart';
import 'package:logix_optiflow/features/production/application/get_work_order_use_case.dart';
import 'package:logix_optiflow/features/production/application/get_workshop_catalog_use_case.dart';
import 'package:logix_optiflow/features/production/application/notify_delivery_delay_use_case.dart';
import 'package:logix_optiflow/features/production/application/send_to_laboratory_use_case.dart';
import 'package:logix_optiflow/features/production/application/update_work_order_status_use_case.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';

class WorkOrderUiState {
  const WorkOrderUiState({
    this.loading = true,
    this.order,
    this.technicians = const [],
    this.laboratories = const [],
    this.showDelay = false,
    this.delayReason = '',
    this.delayDate = '',
    this.saving = false,
    this.error,
    this.message,
  });

  final bool loading;
  final WorkOrderDetail? order;
  final List<NamedRef> technicians;
  final List<NamedRef> laboratories;
  final bool showDelay;
  final String delayReason;
  /// Nueva fecha en dd/mm/aaaa.
  final String delayDate;
  final bool saving;
  final String? error;
  final String? message;

  WorkOrderUiState copyWith({
    bool? loading,
    ValueGetter<WorkOrderDetail?>? order,
    List<NamedRef>? technicians,
    List<NamedRef>? laboratories,
    bool? showDelay,
    String? delayReason,
    String? delayDate,
    bool? saving,
    ValueGetter<String?>? error,
    ValueGetter<String?>? message,
  }) {
    return WorkOrderUiState(
      loading: loading ?? this.loading,
      order: order != null ? order() : this.order,
      technicians: technicians ?? this.technicians,
      laboratories: laboratories ?? this.laboratories,
      showDelay: showDelay ?? this.showDelay,
      delayReason: delayReason ?? this.delayReason,
      delayDate: delayDate ?? this.delayDate,
      saving: saving ?? this.saving,
      error: error != null ? error() : this.error,
      message: message != null ? message() : this.message,
    );
  }
}

/// Seguimiento de una orden en el taller (`GET work-orders/{id}`): el técnico la asigna, la envía al laboratorio,
/// marca los lentes, la avanza por el tablero hasta la entrega y reporta retrasos. Los demás roles solo la leen.
class WorkOrderViewModel extends ChangeNotifier {
  WorkOrderViewModel({
    required this.production,
    required this.getWorkOrderUseCase,
    required this.getWorkshopCatalogUseCase,
    required this.assignTechnicianUseCase,
    required this.sendToLaboratoryUseCase,
    required this.updateWorkOrderStatusUseCase,
    required this.completeLensesUseCase,
    required this.notifyDeliveryDelayUseCase,
  });

  final ProductionViewModel production;
  final GetWorkOrderUseCase getWorkOrderUseCase;
  final GetWorkshopCatalogUseCase getWorkshopCatalogUseCase;
  final AssignTechnicianUseCase assignTechnicianUseCase;
  final SendToLaboratoryUseCase sendToLaboratoryUseCase;
  final UpdateWorkOrderStatusUseCase updateWorkOrderStatusUseCase;
  final CompleteLensesUseCase completeLensesUseCase;
  final NotifyDeliveryDelayUseCase notifyDeliveryDelayUseCase;

  static final _input = DateFormat('dd/MM/yyyy');

  WorkOrderUiState _state = const WorkOrderUiState();
  WorkOrderUiState get state => _state;
  String? _id;
  bool _disposed = false;

  void _emit(WorkOrderUiState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load(String id) async {
    _id = id;
    _emit(const WorkOrderUiState());
    final catalog = getWorkshopCatalogUseCase.execute();
    try {
      final order = await getWorkOrderUseCase.execute(id);
      _emit(_state.copyWith(loading: false, order: () => order));
    } catch (e) {
      _emit(_state.copyWith(loading: false, error: () => _message(e, 'No se pudo cargar la orden.')));
    }
    try {
      final loaded = await catalog;
      _emit(_state.copyWith(technicians: loaded.technicians, laboratories: loaded.laboratories));
    } catch (_) {}
  }

  Future<void> assign(String technicianId) => _run('Técnico asignado.', (id) => assignTechnicianUseCase.execute(id, technicianId));

  Future<void> sendTo(String laboratoryId) =>
      _run('Orden enviada al laboratorio.', (id) => sendToLaboratoryUseCase.execute(id, laboratoryId));

  Future<void> completeAllLenses() => _run('Lentes marcados como fabricados.', (id) => completeLensesUseCase.execute(id));

  Future<void> completeLens(String lensId) => _run('Lente marcado como fabricado.', (id) => completeLensesUseCase.execute(id, [lensId]));

  /// Avanza a la siguiente etapa; en "Lista para entrega" registra la entrega.
  Future<void> advance() async {
    final status = _state.order?.status;
    final next = status == null ? null : WorkOrderStatus.next(status);
    if (next == null) return;
    final done = next == WorkOrderStatus.delivered ? 'Entrega registrada.' : 'Orden en ${WorkOrderStatus.label(next).toLowerCase()}.';
    await _run(done, (id) => updateWorkOrderStatusUseCase.execute(id, next));
  }

  void showDelay(bool show) => _emit(_state.copyWith(showDelay: show, delayReason: '', delayDate: '', error: () => null));

  void setDelayReason(String value) => _emit(_state.copyWith(delayReason: value.length > 255 ? value.substring(0, 255) : value));

  void setDelayDate(String value) => _emit(_state.copyWith(delayDate: value));

  Future<void> reportDelay() async {
    final reason = _state.delayReason.trim();
    if (reason.isEmpty) {
      _emit(_state.copyWith(error: () => 'Escribe el motivo del retraso.'));
      return;
    }
    DateTime? date;
    try {
      date = _input.parseStrict(_state.delayDate);
    } catch (_) {}
    if (date == null) {
      _emit(_state.copyWith(error: () => 'Escribe la nueva fecha como dd/mm/aaaa.'));
      return;
    }
    final current = DateTime.tryParse(_state.order?.estimatedDeliveryDate ?? '');
    if (date.isBefore(StoreTime.today()) || (current != null && !date.isAfter(current))) {
      _emit(_state.copyWith(error: () => 'La nueva fecha debe ser posterior a la entrega actual.'));
      return;
    }
    final iso = StoreTime.isoDay(date);
    await _run('Retraso reportado; se avisó al paciente.', (id) => notifyDeliveryDelayUseCase.execute(id, reason, iso), closeDelay: true);
  }

  Future<void> _run(String done, Future<WorkOrderDetail> Function(String id) call, {bool closeDelay = false}) async {
    final id = _id;
    if (id == null || _state.saving) return;
    _emit(_state.copyWith(saving: true, error: () => null, message: () => null));
    try {
      final order = await call(id);
      _emit(_state.copyWith(saving: false, order: () => order, message: () => done, showDelay: closeDelay ? false : null));
      // El tablero de producción y los contadores se actualizan con el cambio.
      production.refreshStaffOrders();
    } catch (e) {
      _emit(_state.copyWith(saving: false, error: () => _message(e, 'No se pudo guardar el cambio.')));
    }
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;
}
