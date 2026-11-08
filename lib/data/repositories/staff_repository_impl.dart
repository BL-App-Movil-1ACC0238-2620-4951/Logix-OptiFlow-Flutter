import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/production_order.dart';
import '../../domain/entities/staff_alert.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/demo_data.dart';

class StaffRepositoryImpl implements StaffRepository {
  @override
  List<StaffPatient> patients() => DemoData.staffPatients;

  @override
  List<AgendaItem> agenda() => DemoData.agenda;

  @override
  List<ProductItem> products() => DemoData.products;

  @override
  ProductItem product(String id) => DemoData.product(id);

  @override
  List<ProductionOrder> productionOrders() => DemoData.productionOrders;

  @override
  List<StaffAlert> alerts() => DemoData.alerts;

  @override
  List<double> reportBars() => DemoData.reportBars;
}
