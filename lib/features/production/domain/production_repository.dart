import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';

abstract class ProductionRepository {
  Future<List<WorkOrder>> patientWorkOrders(String patientId);
  Future<List<StaffOrder>> orders();
}
