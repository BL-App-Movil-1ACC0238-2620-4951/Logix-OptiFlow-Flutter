import '../entities/product.dart';
import '../entities/production_order.dart';
import '../entities/staff_alert.dart';
import '../entities/staff_patient.dart';
import '../repositories/staff_repository.dart';
import '../entities/staff_order.dart';
import '../entities/appointment.dart';

class GetStaffPatients {
  const GetStaffPatients(this._staff);

  final StaffRepository _staff;

  Future<List<StaffPatient>> call() => _staff.patients();
}

class GetAgenda {
  const GetAgenda(this._staff);

  final StaffRepository _staff;

  Future<List<Appointment>> call(String opticalStoreId, DateTime date) => _staff.agenda(opticalStoreId, date);
}

class GetStaffPatient {
  const GetStaffPatient(this._staff);
  final StaffRepository _staff;
  Future<StaffPatient> call(String id) => _staff.patient(id);
}
class RegisterPatientByStaff {
  const RegisterPatientByStaff(this._staff);
  final StaffRepository _staff;
  Future<StaffPatient> call({required String name, required String email, required String phone, required String dni, DateTime? birthDate}) =>
      _staff.registerPatient(name: name, email: email, phone: phone, dni: dni, birthDate: birthDate);
}
class GetPatientsWithRecords {
  const GetPatientsWithRecords(this._staff);
  final StaffRepository _staff;
  Future<int> call() => _staff.patientsWithRecords();
}
class GetStaffOrders {
  const GetStaffOrders(this._staff);
  final StaffRepository _staff;
  Future<List<StaffOrder>> call() => _staff.orders();
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
