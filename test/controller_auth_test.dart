import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logix_optiflow/core/di/dependencies.dart';
import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/user_role.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'login y reinicio restauran el rol del personal sin cargar datos del paciente',
      () async {
    final paths = <String>[];
    OptiFlowApi createApi() => OptiFlowApi(client: MockClient((request) async {
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
        }));
    final app =
        OptiFlowController(dependencies: AppDependencies(api: createApi()));
    await app.bootstrap();
    await app.login(email: 'tech@optiflow.pe', password: 'password123');
    expect(app.error, isNull);
    expect(app.session?.role, UserRole.technician);
    expect(app.homeRoute, '/s/home');
    expect(app.canOpen('/s/production'), isTrue);
    expect(app.canOpen('/s/inventory'), isFalse);
    expect(paths, ['/api/v1/auth/tokens', '/api/v1/staff-members/tech-1']);

    final restored =
        OptiFlowController(dependencies: AppDependencies(api: createApi()));
    await restored.bootstrap();
    expect(restored.session?.role, UserRole.technician);
    expect(restored.deps.api.token, 'token');
    expect(restored.patientLoading, isFalse);
    await restored.logout();
    expect(restored.session, isNull);
    expect(restored.deps.api.token, isNull);
    expect(restored.homeRoute, '/auth');
    expect(
        (await SharedPreferences.getInstance()).containsKey('token'), isFalse);
    app.dispose();
    restored.dispose();
  });

  test('401 autenticado cierra y borra la sesión persistida', () async {
    SharedPreferences.setMockInitialValues({
      'patient_id': 'admin-1',
      'token': 'expired-token',
      'user_role': 'ADMIN'
    });
    final api =
        OptiFlowApi(client: MockClient((_) async => http.Response('{}', 401)));
    final app = OptiFlowController(dependencies: AppDependencies(api: api));
    await app.bootstrap();
    await expectLater(api.appointments('user-1'), throwsA(isA<ApiException>()));
    // Preferences calls in logout finish asynchronously after the HTTP callback.
    await pumpEventQueue();
    expect(app.session, isNull);
    expect(app.homeRoute, '/auth');
    expect((await SharedPreferences.getInstance()).getString('token'), isNull);
    app.dispose();
  });

  test('registro de personal se rechaza antes de contactar el backend', () {
    final app = OptiFlowController();
    expect(
        app.validateAuth(
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
