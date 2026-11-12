import '../entities/product.dart';
import '../entities/production_order.dart';
import '../entities/staff_alert.dart';
import '../entities/staff_patient.dart';
import '../entities/staff_order.dart';
import '../entities/appointment.dart';

abstract class StaffRepository {
  Future<List<StaffPatient>> patients();
  Future<StaffPatient> patient(String id);
  Future<StaffPatient> registerPatient({required String name, required String email, required String phone, required String dni, DateTime? birthDate});
  Future<int> patientsWithRecords();
  Future<List<StaffOrder>> orders();

  Future<List<Appointment>> agenda(String opticalStoreId, DateTime date);

  List<ProductItem> products();

  ProductItem product(String id);

  List<ProductionOrder> productionOrders();

  List<StaffAlert> alerts();

  List<double> reportBars();
}
