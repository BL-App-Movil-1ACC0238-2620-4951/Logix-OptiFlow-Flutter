import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

import 'support/test_apis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
      'login y reinicio restauran el rol del personal sin cargar datos del paciente',
      () async {
    final paths = <String>[];
    final client = MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/auth/tokens')) {
            return http.Response(
                jsonEncode({
                  'userId': 'tech-1',
                  'token': 'token',
                  'role': 'TECHNICIAN',
                  'expiresAt': DateTime.now()
                      .add(const Duration(hours: 1))
                      .toUtc()
                      .toIso8601String()
                }),
                201);
          }
          return http.Response(
              jsonEncode({
                'id': 'tech-1',
                'name': 'Técnico',
                'email': 'tech@optiflow.pe',
                'opticalStoreId': 'store-1'
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        });
    await setupDependencies(client: client);
    final app = TestApp();
    await app.sessionVm.bootstrap();
    await app.sessionVm.login(email: 'tech@optiflow.pe', password: 'password123');
    expect(app.sessionVm.state.error, isNull);
    expect(app.sessionVm.session?.role, UserRole.technician);
    expect(app.sessionVm.homeRoute, '/s/home');
    expect(app.sessionVm.canOpen('/s/production'), isTrue);
    expect(app.sessionVm.canOpen('/s/inventory'), isFalse);
    expect(paths, ['/api/v1/auth/tokens', '/api/v1/staff-members/tech-1']);

    await setupDependencies(client: client);
    final restored = TestApp();
    await restored.sessionVm.bootstrap();
    expect(restored.sessionVm.session?.role, UserRole.technician);
    expect(getIt<ApiClient>().token, 'token');
    expect(restored.patientVm.state.patientLoading, isFalse);
    await restored.sessionVm.logout();
    expect(restored.sessionVm.session, isNull);
    expect(getIt<ApiClient>().token, isNull);
    expect(restored.sessionVm.homeRoute, '/auth');
    expect(
        (await SharedPreferences.getInstance()).containsKey('token'), isFalse);
    expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
    app.dispose();
    restored.dispose();
  });

  test('401 autenticado cierra y borra la sesión persistida', () async {
    SharedPreferences.setMockInitialValues({
      'patient_id': 'admin-1',
      'user_role': 'ADMIN'
    });
    FlutterSecureStorage.setMockInitialValues({'token': 'expired-token'});
    await setupDependencies(
        client: MockClient((_) async => http.Response('{}', 401)));
    final app = TestApp();
    await app.sessionVm.bootstrap();
    await expectLater(getIt<SearchBookingApi>().appointments('user-1'),
        throwsA(isA<ApiException>()));
    // Preferences calls in logout finish asynchronously after the HTTP callback.
    await pumpEventQueue();
    expect(app.sessionVm.session, isNull);
    expect(app.sessionVm.homeRoute, '/auth');
    expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
    app.dispose();
  });

  test('registro de personal se rechaza antes de contactar el backend',
      () async {
    await setupDependencies();
    final app = TestApp();
    expect(
        app.sessionVm.validateAuth(
            register: true,
            clinical: true,
            name: 'Staff',
            email: 'staff@optiflow.pe',
            phone: '',
            password: 'password123',
            terms: true),
        contains('administrador'));
    app.dispose();
  });
}
