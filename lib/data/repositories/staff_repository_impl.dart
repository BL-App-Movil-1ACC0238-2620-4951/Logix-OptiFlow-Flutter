import '../../domain/entities/product.dart';
import '../../domain/entities/production_order.dart';
import '../../domain/entities/staff_alert.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_local_data_source.dart';
import '../datasources/optiflow_api.dart';
import '../../domain/entities/staff_order.dart';
import '../../domain/entities/appointment.dart';

class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl(this._api, [StaffLocalDataSource? local]) : _local = local ?? StaffLocalDataSource();
  final OptiFlowApi _api;

  final StaffLocalDataSource _local;

  @override
  Future<List<StaffPatient>> patients() => _api.staffPatients();
  @override
  Future<StaffPatient> patient(String id) => _api.staffPatient(id);
  @override
  Future<StaffPatient> registerPatient({required String name, required String email, required String phone, required String dni, DateTime? birthDate}) =>
      _api.registerPatientByStaff(name: name, email: email, phone: phone, dni: dni, birthDate: birthDate);
  @override
  Future<int> patientsWithRecords() => _api.patientsWithRecords();
  @override
  Future<List<StaffOrder>> orders() => _api.staffOrders();

  @override
  Future<List<Appointment>> agenda(String opticalStoreId, DateTime date) async =>
      (await _api.storeAgenda(opticalStoreId, date)).map((dto) => dto.toEntity()).toList();

  @override
  List<ProductItem> products() => StaffLocalDataSource.products;

  @override
  ProductItem product(String id) => _local.product(id);

  @override
  List<ProductionOrder> productionOrders() => StaffLocalDataSource.productionOrders;

  @override
  List<StaffAlert> alerts() => StaffLocalDataSource.alerts;

  @override
  List<double> reportBars() => StaffLocalDataSource.reportBars;
}
