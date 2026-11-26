import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';
import 'package:logix_optiflow/features/production/infrastructure/production_api.dart';
import 'package:logix_optiflow/features/production/infrastructure/production_local_data_source.dart';

class ProductionRepositoryImpl implements ProductionRepository {
  const ProductionRepositoryImpl({required this.api});

  final ProductionApi api;

  @override
  Future<List<WorkOrder>> patientWorkOrders(String patientId) async =>
      (await api.workOrders(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<List<StaffOrder>> orders() => api.staffOrders();
  @override
  List<ProductionOrder> productionOrders() => ProductionLocalDataSource.productionOrders;
}
