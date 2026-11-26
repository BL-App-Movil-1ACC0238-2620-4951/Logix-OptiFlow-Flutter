import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

abstract class ProductionRepository {
  Future<List<WorkOrder>> patientWorkOrders(String patientId);
  Future<List<StaffOrder>> orders();
  Future<WorkOrderDetail> workOrder(String id);
  Future<WorkshopCatalog> workshopCatalog();
  Future<WorkOrderDetail> assignTechnician(String id, String technicianId);
  Future<WorkOrderDetail> sendToLaboratory(String id, String laboratoryId);
  Future<WorkOrderDetail> updateStatus(String id, String status);
  Future<WorkOrderDetail> completeLenses(String id, List<String>? lensIds);
  Future<WorkOrderDetail> notifyDelay(String id, String reason, String newEstimatedDeliveryDate);
}
