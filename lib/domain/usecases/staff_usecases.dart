import '../entities/agenda_item.dart';
import '../entities/product.dart';
import '../entities/production_order.dart';
import '../entities/staff_alert.dart';
import '../entities/staff_patient.dart';
import '../repositories/staff_repository.dart';

class GetStaffPatients {
  const GetStaffPatients(this._staff);

  final StaffRepository _staff;

  List<StaffPatient> call() => _staff.patients();
}

class GetAgenda {
  const GetAgenda(this._staff);

  final StaffRepository _staff;

  List<AgendaItem> call() => _staff.agenda();
}

class GetProducts {
  const GetProducts(this._staff);

  final StaffRepository _staff;

  List<ProductItem> call() => _staff.products();
}

class GetProduct {
  const GetProduct(this._staff);

  final StaffRepository _staff;

  ProductItem call(String id) => _staff.product(id);
}

class GetProductionOrders {
  const GetProductionOrders(this._staff);

  final StaffRepository _staff;

  List<ProductionOrder> call() => _staff.productionOrders();
}

class GetStaffAlerts {
  const GetStaffAlerts(this._staff);

  final StaffRepository _staff;

  List<StaffAlert> call() => _staff.alerts();
}

class GetReportBars {
  const GetReportBars(this._staff);

  final StaffRepository _staff;

  List<double> call() => _staff.reportBars();
}
