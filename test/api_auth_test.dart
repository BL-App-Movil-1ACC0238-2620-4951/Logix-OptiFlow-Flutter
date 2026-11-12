import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/user_role.dart';

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, Object> loginResponse(String role) => {
      'token': 'test-token',
      'userId': 'user-1',
      'role': role,
      'expiresAt': DateTime.now()
          .add(const Duration(hours: 1))
          .toUtc()
          .toIso8601String(),
    };

void main() {
  for (final role in UserRole.values) {
    test('login ${role.apiValue} carga perfil con bearer y conserva rol',
        () async {
      final requests = <http.Request>[];
      final api = OptiFlowApi(
          baseUrl: 'http://localhost:8080/',
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path.endsWith('/auth/tokens')) {
              expect(request.method, 'POST');
              expect(request.headers['Authorization'], isNull);
              expect(jsonDecode(request.body),
                  {'email': 'user@optiflow.pe', 'password': 'password123'});
              return jsonResponse(loginResponse(role.apiValue), 201);
            }
            expect(request.headers['Authorization'], 'Bearer test-token');
            expect(request.url.path,
                '/api/v1/${role == UserRole.patient ? 'patients' : 'staff-members'}/user-1');
            return jsonResponse({
              'id': 'user-1',
              'name': 'Usuario real',
              'email': 'user@optiflow.pe',
              'phone': '999888777',
              if (role != UserRole.patient) 'opticalStoreId': 'store-1'
            });
          }));
      api.token = 'previous-account';
      final session =
          (await api.login(email: 'user@optiflow.pe', password: 'password123'))
              .toEntity();
      expect(requests.first.url.path, '/api/v1/auth/tokens');
      expect(requests, hasLength(2));
      expect(session.isAuthenticated, isTrue);
      expect(session.role, role);
      expect(session.name, 'Usuario real');
      expect(session.opticalStoreId,
          role == UserRole.patient ? isNull : 'store-1');
    });
  }

  test('401 de login no dispara expiración de una sesión', () async {
    var expired = false;
    final api =
        OptiFlowApi(client: MockClient((_) async => jsonResponse({}, 401)));
    api.onUnauthorized = () => expired = true;
    await expectLater(
        api.login(email: 'bad@optiflow.pe', password: 'wrong'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(expired, isFalse);
    expect(api.token, isNull);
  });

  test('un 401 autenticado limpia token y avisa; un 403 conserva sesión',
      () async {
    for (final status in [401, 403]) {
      var expired = false;
      final api = OptiFlowApi(
          client: MockClient((_) async =>
              jsonResponse({'detail': 'Acceso rechazado'}, status)));
      api.token = 'active-token';
      api.onUnauthorized = () => expired = true;
      await expectLater(
          api.appointments('user-1'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Acceso rechazado')));
      expect(expired, status == 401);
      expect(api.token, status == 401 ? isNull : 'active-token');
    }
  });

  test('un 401 tardío de otra sesión no cierra la cuenta actual', () async {
    final pending = Completer<http.Response>();
    var expired = false;
    final api = OptiFlowApi(client: MockClient((_) => pending.future));
    api.token = 'old-token';
    api.onUnauthorized = () => expired = true;
    final request = api.appointments('old-user');
    final assertion = expectLater(request, throwsA(isA<ApiException>()));
    api.token = 'new-token';
    pending.complete(jsonResponse({}, 401));
    await assertion;
    expect(expired, isFalse);
    expect(api.token, 'new-token');
  });

  test('login rechaza roles desconocidos y tokens vacíos', () async {
    for (final response in [
      {...loginResponse('SUPERADMIN')},
      {...loginResponse('PATIENT'), 'token': ''},
      {...loginResponse('PATIENT'), 'userId': ''},
      {...loginResponse('PATIENT'), 'expiresAt': 'invalid-date'},
      {...loginResponse('PATIENT'), 'expiresAt': '2000-01-01T00:00:00Z'},
    ]) {
      final api =
          OptiFlowApi(client: MockClient((_) async => jsonResponse(response)));
      await expectLater(
          api.login(email: 'user@optiflow.pe', password: 'password123'),
          throwsA(isA<ApiException>()));
      expect(api.token, isNull);
    }
  });

  test(
      'mantiene /api/v1 una vez y usa endpoints actuales para búsqueda y horarios',
      () async {
    final urls = <Uri>[];
    final api = OptiFlowApi(
        baseUrl: 'http://localhost:8080/api/v1/',
        client: MockClient((request) async {
          urls.add(request.url);
          return jsonResponse([]);
        }));
    await api.searchStores(name: ' Centro ', minRating: 4);
    await api.availability('store-1');
    expect(urls[0].path, '/api/v1/optical-stores');
    expect(urls[0].queryParameters, {'name': 'Centro', 'minRating': '4.0'});
    expect(urls[1].path, '/api/v1/optical-stores/store-1/time-slots');
  });
}
