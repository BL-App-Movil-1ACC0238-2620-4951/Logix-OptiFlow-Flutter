import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_apis.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/staff_api_checks.dart';

Future<TestApp> staffController(
    Future<http.Response> Function(http.Request) handler,
    {UserRole role = UserRole.admin,
    String? storeId = 'store-1'}) async {
  final api = await setupTestDependencies(MockClient(handler));
  final app = TestApp();
  app.sessionVm.session = PatientSession(
      patientId: 'staff-1',
      name: 'Staff',
      email: 'staff@example.test',
      token: 'staff-token',
      role: role,
      opticalStoreId: storeId);
  api.token = 'staff-token';
  addTearDown(app.dispose);
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('contratos HTTP y reglas de Movile', runStaffApiChecks);

  test('registro no cambia la cuenta del personal y evita doble POST',
      () async {
    final pending = Completer<http.Response>();
    var posts = 0;
    final app = await staffController((request) async {
      posts++;
      return pending.future;
    });
    final account = app.sessionVm.session;
    final saved = app.patientsVm.registerStaffPatient(
        name: 'Camila Paz Morales',
        email: 'camila@example.test',
        phone: '987654321',
        dni: '12345678',
        birthDate: '24/05/1990');
    expect(
        await app.patientsVm.registerStaffPatient(
            name: 'Camila Paz Morales',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678'),
        isNull);
    pending.complete(staffResponse(staffPatientFixture, 201));
    expect(await saved, 'patient-1');
    expect(posts, 1);
    expect(identical(app.sessionVm.session, account), isTrue);
    expect(getIt<ApiClient>().token, 'staff-token');
    expect(app.patientsVm.staffPatient('patient-1')?.email, 'camila@example.test');
    expect(app.patientsVm.staffPatient('unknown'), isNull);
  });

  test('validaciones de DNI, fecha y permisos rechazan el envío', () async {
    var calls = 0;
    final app = await staffController((_) async {
      calls++;
      return staffResponse(staffPatientFixture);
    });
    for (final dni in ['123', '1234567A']) {
      expect(
          await app.patientsVm.registerStaffPatient(
              name: 'Camila',
              email: 'camila@example.test',
              phone: '987654321',
              dni: dni),
          isNull);
    }
    expect(
        await app.patientsVm.registerStaffPatient(
            name: 'Camila',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678',
            birthDate: '31/02/2000'),
        isNull);
    final technician = await staffController((_) async {
      calls++;
      return staffResponse(staffPatientFixture);
    }, role: UserRole.technician);
    expect(
        await technician.patientsVm.registerStaffPatient(
            name: 'Camila',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678'),
        isNull);
    expect(calls, 0);
  });

  test('agenda sin óptica asignada no realiza solicitudes', () async {
    var calls = 0;
    final app = await staffController((_) async {
      calls++;
      return staffResponse([]);
    }, storeId: null);
    await app.agendaVm.refreshStaffAgenda();
    expect(calls, 0);
    expect(app.agendaVm.state.agenda, isEmpty);
    expect(app.agendaVm.state.error, contains('óptica asignada'));
  });

  test('agenda descarta respuestas antiguas y excluye citas canceladas',
      () async {
    final pending = Completer<http.Response>();
    final app = await staffController((request) async {
      if (request.url.path.endsWith('/patients/patient-1')) {
        return staffResponse(staffPatientFixture);
      }
      if (request.url.queryParameters['date'] == '2026-11-11') {
        return pending.future;
      }
      return staffResponse([
        staffAppointmentFixture,
        {...staffAppointmentFixture, 'id': 'cancelled', 'status': 'CANCELLED'}
      ]);
    });
    final old = app.agendaVm.refreshStaffAgenda(date: DateTime(2026, 11, 11));
    await app.agendaVm.refreshStaffAgenda(date: DateTime(2026, 11, 12));
    pending.complete(staffResponse([]));
    await old;
    expect(app.agendaVm.state.agenda.single.appointmentId, 'appointment-1');
    expect(app.agendaVm.state.date, DateTime(2026, 11, 12));
    expect(app.agendaVm.state.agenda.single.name, 'Camila Paz Morales');
  });

  test('error de registro no crea un paciente local', () async {
    final app = await staffController(
        (_) async => staffResponse({'message': 'Correo ya registrado'}, 409));
    expect(
        await app.patientsVm.registerStaffPatient(
            name: 'Camila',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678'),
        isNull);
    expect(app.patientsVm.state.patients, isEmpty);
    expect(app.patientsVm.state.saveError, 'Correo ya registrado');
  });

  test('logout descarta directorio en vuelo y no restaura datos de la cuenta',
      () async {
    final pending = Completer<http.Response>();
    final app = await staffController((_) => pending.future);
    final loading = app.patientsVm.refreshStaffPatients();
    await app.sessionVm.logout();
    pending.complete(staffResponse([staffPatientFixture]));
    await loading;
    expect(app.patientsVm.state.patients, isEmpty);
    expect(app.patientsVm.staffPatient('patient-1'), isNull);
    expect(app.agendaVm.state.agenda, isEmpty);
  });

  test('booking de personal usa paciente elegido y recarga horarios ante 409',
      () async {
    var posts = 0;
    final start = DateTime.now().add(const Duration(days: 2));
    final app = await staffController((request) async {
      if (request.method == 'POST') {
        posts++;
        return staffResponse({'message': 'Horario ocupado'}, 409);
      }
      if (request.url.path.endsWith('/patients')) {
        return staffResponse([staffPatientFixture]);
      }
      if (request.url.path.endsWith('/summary')) {
        return staffResponse({'patientsWithRecords': 1});
      }
      return staffResponse([
        {
          'id': 'slot-1',
          'opticalStoreId': 'store-1',
          'status': 'AVAILABLE',
          'startDateTime': start.toUtc().toIso8601String(),
          'endDateTime':
              start.add(const Duration(minutes: 30)).toUtc().toIso8601String()
        }
      ]);
    });
    await app.agendaVm.prepareStaffBooking(patientId: 'patient-1');
    app.agendaVm.selectStaffBooking(slotId: 'slot-1');
    expect(await app.agendaVm.confirmStaffBooking(), isFalse);
    expect(posts, 1);
    expect(app.agendaVm.state.bookingSlotId, isNull);
    expect(app.agendaVm.state.bookingError, 'Horario ocupado');
    expect(app.agendaVm.state.bookingSlots, hasLength(1));
    expect(app.sessionVm.session?.patientId, 'staff-1');
  });
}
