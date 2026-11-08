import '../network/optiflow_api.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/store_usecases.dart';

/// Composition root: API, repositories and use cases.
class AppDependencies {
  AppDependencies({OptiFlowApi? api}) : api = api ?? OptiFlowApi() {
    final patients = PatientRepositoryImpl(this.api);
    final stores = StoreRepositoryImpl(this.api);
    final appointments = AppointmentRepositoryImpl(this.api);
    loginPatient = LoginPatient(patients);
    registerPatient = RegisterPatient(patients);
    getStores = GetOpticalStores(stores);
    searchStores = SearchOpticalStores(stores);
    getAvailability = GetStoreAvailability(stores);
    getAppointments = GetPatientAppointments(appointments);
    bookAppointment = BookAppointment(appointments);
    getWorkOrders = GetPatientWorkOrders(appointments);
    getClinicalRecords = GetPatientClinicalRecords(appointments);
  }

  final OptiFlowApi api;
  late final LoginPatient loginPatient;
  late final RegisterPatient registerPatient;
  late final GetOpticalStores getStores;
  late final SearchOpticalStores searchStores;
  late final GetStoreAvailability getAvailability;
  late final GetPatientAppointments getAppointments;
  late final BookAppointment bookAppointment;
  late final GetPatientWorkOrders getWorkOrders;
  late final GetPatientClinicalRecords getClinicalRecords;
}
