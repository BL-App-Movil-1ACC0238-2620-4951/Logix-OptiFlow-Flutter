import '../entities/agenda_item.dart';
import '../entities/product.dart';
import '../entities/production_order.dart';
import '../entities/staff_alert.dart';
import '../entities/staff_patient.dart';

abstract class StaffRepository {
  List<StaffPatient> patients();

  List<AgendaItem> agenda();

  List<ProductItem> products();

  ProductItem product(String id);

  List<ProductionOrder> productionOrders();

  List<StaffAlert> alerts();

  List<double> reportBars();
}
