import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';
import 'package:logix_optiflow/features/production/infrastructure/production_api.dart';

class ProductionRepositoryImpl implements ProductionRepository {
  const ProductionRepositoryImpl({required this.api});

  final ProductionApi api;

  @override
  Future<List<WorkOrder>> patientWorkOrders(String patientId) async =>
      (await api.workOrders(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<List<StaffOrder>> orders() => api.staffOrders();
  @override
  Future<WorkOrderDetail> workOrder(String id) => api.workOrder(id);
  @override
  Future<WorkshopCatalog> workshopCatalog() async {
    // Si falla una de las dos listas, la orden igual se muestra sin esas opciones.
    final results = await Future.wait([
      api.technicians().catchError((_) => <NamedRef>[]),
      api.laboratories().catchError((_) => <NamedRef>[]),
    ]);
    return WorkshopCatalog(technicians: results[0], laboratories: results[1]);
  }
  @override
  Future<WorkOrderDetail> assignTechnician(String id, String technicianId) => api.assignTechnician(id, technicianId);
  @override
  Future<WorkOrderDetail> sendToLaboratory(String id, String laboratoryId) => api.sendToLaboratory(id, laboratoryId);
  @override
  Future<WorkOrderDetail> updateStatus(String id, String status) async {
    await api.updateStatus(id, status);
    return api.workOrder(id);
  }
  @override
  Future<WorkOrderDetail> completeLenses(String id, List<String>? lensIds) => api.completeLenses(id, lensIds);
  @override
  Future<WorkOrderDetail> notifyDelay(String id, String reason, String newEstimatedDeliveryDate) =>
      api.notifyDelay(id, reason, newEstimatedDeliveryDate);
}
