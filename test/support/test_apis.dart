import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/auth/infrastructure/auth_api.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/clinical_api.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/commerce_api.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_api.dart';
import 'package:logix_optiflow/features/production/infrastructure/production_api.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';
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

/// Las APIs de todos los contextos sobre un mismo [ApiClient] de prueba.
class TestApis {
  TestApis({http.Client? client, String? baseUrl}) : client = ApiClient(client: client, baseUrl: baseUrl);

  final ApiClient client;
  late final auth = AuthApi(client);
  late final booking = SearchBookingApi(client);
  late final clinical = ClinicalApi(client);
  late final commerce = CommerceApi(client);
  late final production = ProductionApi(client);
  late final inventory = InventoryApi(client);

  String? get token => client.token;
  set token(String? value) => client.token = value;
  set onUnauthorized(void Function()? value) => client.onUnauthorized = value;
}

/// Registra las dependencias con [client] y un almacenamiento seguro vacío.
Future<ApiClient> setupTestDependencies(http.Client client) async {
  FlutterSecureStorage.setMockInitialValues({});
  await setupDependencies(client: client);
  return getIt<ApiClient>();
}

/// ViewModels registrados en get_it al momento de crearse, como los usa la app.
class TestApp {
  final SessionViewModel sessionVm = getIt();
  final PatientViewModel patientVm = getIt();
  final BookingViewModel bookingVm = getIt();
  final StoreSearchViewModel storesVm = getIt();
  final CatalogViewModel catalogVm = getIt();
  final ProductionViewModel productionVm = getIt();
  final ReportViewModel reportVm = getIt();
  final StaffPatientsViewModel patientsVm = getIt();
  final AgendaViewModel agendaVm = getIt();
  final ClinicalCareViewModel careVm = getIt();
  final QuoteViewModel quoteVm = getIt();
  final SaleViewModel saleVm = getIt();

  void dispose() {
    for (final vm in [saleVm, quoteVm, careVm, agendaVm, patientsVm, reportVm, productionVm, catalogVm, storesVm, bookingVm, patientVm, sessionVm]) {
      vm.dispose();
    }
  }
}

/// ViewModels sobre dependencias registradas con [client].
Future<TestApp> testController(http.Client client) async {
  await setupTestDependencies(client);
  return TestApp();
}
