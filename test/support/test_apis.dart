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
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';

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

/// Controlador sobre dependencias registradas con [client].
Future<OptiFlowController> testController(http.Client client) async {
  await setupTestDependencies(client);
  return OptiFlowController();
}
