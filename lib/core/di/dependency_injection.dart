import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/core/storage/secure_token_storage.dart';
import 'package:logix_optiflow/core/storage/token_storage.dart';
import 'package:logix_optiflow/features/auth/application/clear_session_use_case.dart';
import 'package:logix_optiflow/features/auth/application/load_app_settings_use_case.dart';
import 'package:logix_optiflow/features/auth/application/load_session_use_case.dart';
import 'package:logix_optiflow/features/auth/application/login_use_case.dart';
import 'package:logix_optiflow/features/auth/application/register_patient_use_case.dart';
import 'package:logix_optiflow/features/auth/application/save_app_settings_use_case.dart';
import 'package:logix_optiflow/features/auth/application/save_session_use_case.dart';
import 'package:logix_optiflow/features/auth/domain/auth_repository.dart';
import 'package:logix_optiflow/features/auth/domain/session_repository.dart';
import 'package:logix_optiflow/features/auth/infrastructure/auth_api.dart';
import 'package:logix_optiflow/features/auth/infrastructure/auth_repository_impl.dart';
import 'package:logix_optiflow/features/auth/infrastructure/session_local_data_source.dart';
import 'package:logix_optiflow/features/auth/infrastructure/session_repository_impl.dart';
import 'package:logix_optiflow/features/clinical/application/get_patient_clinical_records_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_patients_with_records_use_case.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_repository.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/clinical_api.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/clinical_repository_impl.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/commerce_api.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/commerce_repository_impl.dart';
import 'package:logix_optiflow/features/inventory/application/get_frame_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_low_stock_alerts_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_frames_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_stock_movements_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_store_stock_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/get_suppliers_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/replenish_stock_use_case.dart';
import 'package:logix_optiflow/features/inventory/application/update_frame_price_use_case.dart';
import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory_repository.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/catalog_repository_impl.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_api.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_repository_impl.dart';
import 'package:logix_optiflow/features/notification/application/load_read_notifications_use_case.dart';
import 'package:logix_optiflow/features/notification/application/save_read_notifications_use_case.dart';
import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';
import 'package:logix_optiflow/features/notification/infrastructure/notification_local_data_source.dart';
import 'package:logix_optiflow/features/notification/infrastructure/notification_repository_impl.dart';
import 'package:logix_optiflow/features/production/application/get_patient_work_orders_use_case.dart';
import 'package:logix_optiflow/features/production/application/get_staff_orders_use_case.dart';
import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/infrastructure/production_api.dart';
import 'package:logix_optiflow/features/production/infrastructure/production_repository_impl.dart';
import 'package:logix_optiflow/features/report/application/get_monthly_report_use_case.dart';
import 'package:logix_optiflow/features/report/domain/report_repository.dart';
import 'package:logix_optiflow/features/report/infrastructure/report_api.dart';
import 'package:logix_optiflow/features/report/infrastructure/report_repository_impl.dart';
import 'package:logix_optiflow/features/searchbooking/application/book_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/cancel_appointment_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_agenda_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_patient_appointments_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patient_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patients_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_store_availability_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/register_patient_by_staff_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/search_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/patient_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/appointment_repository_impl.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/patient_repository_impl.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/store_repository_impl.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/presentation/clinical_care_view_model.dart';
import 'package:logix_optiflow/features/clinical/presentation/quote_view_model.dart';
import 'package:logix_optiflow/features/clinical/presentation/sale_view_model.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/report/presentation/report_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';

final getIt = GetIt.instance;

/// Registra APIs, repositorios y casos de uso. Las pruebas pasan su propio [client] y [tokenStorage].
Future<void> setupDependencies({http.Client? client, String? baseUrl, TokenStorage? tokenStorage}) async {
  await getIt.reset();

  // core
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(client: client, baseUrl: baseUrl));
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<TokenStorage>(
    () => tokenStorage ?? SecureTokenStorage(storage: getIt<FlutterSecureStorage>()),
  );

  // APIs por contexto
  getIt.registerLazySingleton<AuthApi>(() => AuthApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<SearchBookingApi>(() => SearchBookingApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<ClinicalApi>(() => ClinicalApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<CommerceApi>(() => CommerceApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<ProductionApi>(() => ProductionApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<InventoryApi>(() => InventoryApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<ReportApi>(() => ReportApi(getIt<ApiClient>()));

  // auth
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(api: getIt<AuthApi>()));
  getIt.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(local: SessionLocalDataSource(tokens: getIt<TokenStorage>())),
  );
  getIt.registerLazySingleton(() => LoginUseCase(repository: getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterPatientUseCase(repository: getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LoadSessionUseCase(repository: getIt<SessionRepository>()));
  getIt.registerLazySingleton(() => SaveSessionUseCase(repository: getIt<SessionRepository>()));
  getIt.registerLazySingleton(() => ClearSessionUseCase(repository: getIt<SessionRepository>()));
  getIt.registerLazySingleton(() => LoadAppSettingsUseCase(repository: getIt<SessionRepository>()));
  getIt.registerLazySingleton(() => SaveAppSettingsUseCase(repository: getIt<SessionRepository>()));

  // notification
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(local: NotificationLocalDataSource()),
  );
  getIt.registerLazySingleton(() => LoadReadNotificationsUseCase(repository: getIt<NotificationRepository>()));
  getIt.registerLazySingleton(() => SaveReadNotificationsUseCase(repository: getIt<NotificationRepository>()));

  // searchbooking
  getIt.registerLazySingleton<StoreRepository>(() => StoreRepositoryImpl(api: getIt<SearchBookingApi>()));
  getIt.registerLazySingleton<AppointmentRepository>(() => AppointmentRepositoryImpl(api: getIt<SearchBookingApi>()));
  getIt.registerLazySingleton<PatientRepository>(() => PatientRepositoryImpl(api: getIt<SearchBookingApi>()));
  getIt.registerLazySingleton(() => GetOpticalStoresUseCase(repository: getIt<StoreRepository>()));
  getIt.registerLazySingleton(() => SearchOpticalStoresUseCase(repository: getIt<StoreRepository>()));
  getIt.registerLazySingleton(() => GetStoreAvailabilityUseCase(repository: getIt<StoreRepository>()));
  getIt.registerLazySingleton(() => GetPatientAppointmentsUseCase(repository: getIt<AppointmentRepository>()));
  getIt.registerLazySingleton(() => CancelAppointmentUseCase(repository: getIt<AppointmentRepository>()));
  getIt.registerLazySingleton(() => BookAppointmentUseCase(repository: getIt<AppointmentRepository>()));
  getIt.registerLazySingleton(() => GetAgendaUseCase(repository: getIt<AppointmentRepository>()));
  getIt.registerLazySingleton(() => GetStaffPatientsUseCase(repository: getIt<PatientRepository>()));
  getIt.registerLazySingleton(() => GetStaffPatientUseCase(repository: getIt<PatientRepository>()));
  getIt.registerLazySingleton(() => RegisterPatientByStaffUseCase(repository: getIt<PatientRepository>()));

  // clinical
  getIt.registerLazySingleton<ClinicalRepository>(
    () => ClinicalRepositoryImpl(api: getIt<ClinicalApi>(), bookingApi: getIt<SearchBookingApi>()),
  );
  getIt.registerLazySingleton<CommerceRepository>(
    () => CommerceRepositoryImpl(
      api: getIt<CommerceApi>(),
      clinicalApi: getIt<ClinicalApi>(),
      bookingApi: getIt<SearchBookingApi>(),
      inventoryApi: getIt<InventoryApi>(),
    ),
  );
  getIt.registerLazySingleton(() => GetPatientClinicalRecordsUseCase(repository: getIt<ClinicalRepository>()));
  getIt.registerLazySingleton(() => GetPatientsWithRecordsUseCase(repository: getIt<ClinicalRepository>()));

  // production
  getIt.registerLazySingleton<ProductionRepository>(() => ProductionRepositoryImpl(api: getIt<ProductionApi>()));
  getIt.registerLazySingleton(() => GetPatientWorkOrdersUseCase(repository: getIt<ProductionRepository>()));
  getIt.registerLazySingleton(() => GetStaffOrdersUseCase(repository: getIt<ProductionRepository>()));

  // inventory
  getIt.registerLazySingleton<CatalogRepository>(() => CatalogRepositoryImpl(api: getIt<InventoryApi>()));
  getIt.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl(api: getIt<InventoryApi>()));
  getIt.registerLazySingleton(() => GetFramesUseCase(repository: getIt<CatalogRepository>()));
  getIt.registerLazySingleton(() => GetFrameUseCase(repository: getIt<CatalogRepository>()));
  getIt.registerLazySingleton(() => UpdateFramePriceUseCase(repository: getIt<CatalogRepository>()));
  getIt.registerLazySingleton(() => GetStoreStockUseCase(repository: getIt<InventoryRepository>()));
  getIt.registerLazySingleton(() => GetSuppliersUseCase(repository: getIt<InventoryRepository>()));
  getIt.registerLazySingleton(() => GetStockMovementsUseCase(repository: getIt<InventoryRepository>()));
  getIt.registerLazySingleton(() => ReplenishStockUseCase(repository: getIt<InventoryRepository>()));
  getIt.registerLazySingleton(() => GetLowStockAlertsUseCase(repository: getIt<InventoryRepository>()));

  // report
  getIt.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(api: getIt<ReportApi>()));
  getIt.registerLazySingleton(() => GetMonthlyReportUseCase(repository: getIt<ReportRepository>()));

  // ViewModels: uno por área, compartidos por las pantallas.
  getIt.registerLazySingleton(() => SessionViewModel(
        api: getIt<ApiClient>(),
        loadSessionUseCase: getIt(),
        saveSessionUseCase: getIt(),
        clearSessionUseCase: getIt(),
        loginUseCase: getIt(),
        registerPatientUseCase: getIt(),
        loadAppSettingsUseCase: getIt(),
        saveAppSettingsUseCase: getIt(),
      ));
  getIt.registerLazySingleton(() => StoreSearchViewModel(
        session: getIt(), getOpticalStoresUseCase: getIt(), searchOpticalStoresUseCase: getIt()));
  getIt.registerLazySingleton(() => PatientViewModel(
        session: getIt(),
        stores: getIt(),
        getPatientAppointmentsUseCase: getIt(),
        cancelAppointmentUseCase: getIt(),
        getPatientWorkOrdersUseCase: getIt(),
        getPatientClinicalRecordsUseCase: getIt(),
        loadReadNotificationsUseCase: getIt(),
        saveReadNotificationsUseCase: getIt(),
      ));
  getIt.registerLazySingleton(() => BookingViewModel(
        session: getIt(),
        patient: getIt(),
        stores: getIt(),
        getStoreAvailabilityUseCase: getIt(),
        bookAppointmentUseCase: getIt(),
        cancelAppointmentUseCase: getIt(),
      ));
  getIt.registerLazySingleton(() => CatalogViewModel(
        session: getIt(),
        getFramesUseCase: getIt(),
        getFrameUseCase: getIt(),
        updateFramePriceUseCase: getIt(),
        getStoreStockUseCase: getIt(),
        getSuppliersUseCase: getIt(),
        getStockMovementsUseCase: getIt(),
        replenishStockUseCase: getIt(),
      ));
  getIt.registerLazySingleton(() => StaffPatientsViewModel(
        session: getIt(),
        getStaffPatientsUseCase: getIt(),
        getStaffPatientUseCase: getIt(),
        registerPatientByStaffUseCase: getIt(),
        getPatientsWithRecordsUseCase: getIt(),
        getPatientClinicalRecordsUseCase: getIt(),
        getPatientAppointmentsUseCase: getIt(),
        getStaffOrdersUseCase: getIt(),
      ));
  getIt.registerLazySingleton(() => ProductionViewModel(
        session: getIt(), patients: getIt(), getStaffOrdersUseCase: getIt(), getStaffPatientUseCase: getIt()));
  getIt.registerLazySingleton(() => AgendaViewModel(
        session: getIt(),
        patients: getIt(),
        production: getIt(),
        stores: getIt(),
        getAgendaUseCase: getIt(),
        getStaffPatientUseCase: getIt(),
        getStoreAvailabilityUseCase: getIt(),
        bookAppointmentUseCase: getIt(),
      ));
  getIt.registerLazySingleton(() => ReportViewModel(
        session: getIt(), production: getIt(), getLowStockAlertsUseCase: getIt(), getMonthlyReportUseCase: getIt()));
  getIt.registerLazySingleton(() => ClinicalCareViewModel(
        session: getIt(), repository: getIt(), agenda: getIt(), patients: getIt()));
  getIt.registerLazySingleton(() => QuoteViewModel(session: getIt(), repository: getIt()));
  getIt.registerLazySingleton(() => SaleViewModel(
        session: getIt(), repository: getIt(), patients: getIt(), catalog: getIt()));

  // Se crean ya, para que se suscriban al cierre de sesión antes del primer login.
  getIt<PatientViewModel>();
  getIt<BookingViewModel>();
  getIt<AgendaViewModel>();
  getIt<ClinicalCareViewModel>();
  getIt<QuoteViewModel>();
  getIt<SaleViewModel>();
}
