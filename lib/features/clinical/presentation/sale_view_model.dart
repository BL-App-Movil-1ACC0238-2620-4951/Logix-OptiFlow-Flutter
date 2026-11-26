import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';
import 'package:logix_optiflow/features/clinical/presentation/sale_flow.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';

/// Ventas de un paciente: lista, cobro en efectivo y cierre.
class SaleViewModel extends ChangeNotifier {
  SaleViewModel({required this.session, required this.repository, required this.patients, required this.catalog}) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final CommerceRepository repository;
  final StaffPatientsViewModel patients;
  final CatalogViewModel catalog;

  /// Venta en curso; se reemplaza al abrir otra.
  SaleFlow? get flow => _flow;
  SaleFlow? _flow;

  void _reset() {
    _flow?.dispose();
    _flow = null;
    notifyListeners();
  }

  Future<void> open(String patientId, {String? saleId}) async {
    if (!session.canOpen('/s/sale')) return;
    final current = session.session;
    _flow?.dispose();
    final flow = SaleFlow(repository: repository, patientId: patientId, saleId: saleId,
      isActive: () => identical(current, session.session) && session.canOpen('/s/sale'), onChanged: notifyListeners,
      onClosed: () async {
        await patients.loadStaffRecord(patientId);
        if (identical(current, session.session) && session.canOpen('/s/inventory')) await catalog.refreshInventory();
      });
    _flow = flow;
    await flow.refresh();
  }

  @override
  void dispose() {
    _flow?.dispose();
    super.dispose();
  }
}
