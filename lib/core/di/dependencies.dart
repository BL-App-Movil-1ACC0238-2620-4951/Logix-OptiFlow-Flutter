import '../../data/datasources/optiflow_api.dart';
import '../../data/datasources/session_local_data_source.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/session_usecases.dart';
import '../../domain/usecases/store_usecases.dart';

/// Composition root: API, repositories and use cases.
class AppDependencies {
  AppDependencies({OptiFlowApi? api, SessionRepository? sessions}) : api = api ?? OptiFlowApi() {
    final patients = PatientRepositoryImpl(this.api);
    final stores = StoreRepositoryImpl(this.api);
    final appointments = AppointmentRepositoryImpl(this.api);
    final sessionRepository = sessions ?? SessionRepositoryImpl(SessionLocalDataSource());
    loginPatient = LoginPatient(patients);
    registerPatient = RegisterPatient(patients);
    loadSession = LoadSession(sessionRepository);
    saveSession = SaveSession(sessionRepository);
    clearSession = ClearSession(sessionRepository);
    loadReadNotifications = LoadReadNotifications(sessionRepository);
    saveReadNotifications = SaveReadNotifications(sessionRepository);
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
  late final LoadSession loadSession;
  late final SaveSession saveSession;
  late final ClearSession clearSession;
  late final LoadReadNotifications loadReadNotifications;
  late final SaveReadNotifications saveReadNotifications;
  late final GetOpticalStores getStores;
  late final SearchOpticalStores searchStores;
  late final GetStoreAvailability getAvailability;
  late final GetPatientAppointments getAppointments;
  late final BookAppointment bookAppointment;
  late final GetPatientWorkOrders getWorkOrders;
  late final GetPatientClinicalRecords getClinicalRecords;
}
