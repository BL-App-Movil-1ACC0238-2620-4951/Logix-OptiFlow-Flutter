import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/di/dependencies.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/models.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/staff_api_checks.dart';

OptiFlowController staffController(
    Future<http.Response> Function(http.Request) handler,
    {UserRole role = UserRole.admin,
    String? storeId = 'store-1'}) {
  final api = OptiFlowApi(client: MockClient(handler));
  final app = OptiFlowController(dependencies: AppDependencies(api: api));
  app.session = PatientSession(
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
    final app = staffController((request) async {
      posts++;
      return pending.future;
    });
    final account = app.session;
    final saved = app.registerStaffPatient(
        name: 'Camila Paz Morales',
        email: 'camila@example.test',
        phone: '987654321',
        dni: '12345678',
        birthDate: '24/05/1990');
    expect(
        await app.registerStaffPatient(
            name: 'Camila Paz Morales',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678'),
        isNull);
    pending.complete(staffResponse(staffPatientFixture, 201));
    expect(await saved, 'patient-1');
    expect(posts, 1);
    expect(identical(app.session, account), isTrue);
    expect(app.deps.api.token, 'staff-token');
    expect(app.staffPatient('patient-1')?.email, 'camila@example.test');
    expect(app.staffPatient('unknown'), isNull);
  });

  test('validaciones de DNI, fecha y permisos rechazan el envío', () async {
    var calls = 0;
    final app = staffController((_) async {
      calls++;
      return staffResponse(staffPatientFixture);
    });
    for (final dni in ['123', '1234567A']) {
      expect(
          await app.registerStaffPatient(
              name: 'Camila',
              email: 'camila@example.test',
              phone: '987654321',
              dni: dni),
          isNull);
    }
    expect(
        await app.registerStaffPatient(
            name: 'Camila',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678',
            birthDate: '31/02/2000'),
        isNull);
    final technician = staffController((_) async {
      calls++;
      return staffResponse(staffPatientFixture);
    }, role: UserRole.technician);
    expect(
        await technician.registerStaffPatient(
            name: 'Camila',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678'),
        isNull);
    expect(calls, 0);
  });

  test('agenda sin óptica asignada no realiza solicitudes', () async {
    var calls = 0;
    final app = staffController((_) async {
      calls++;
      return staffResponse([]);
    }, storeId: null);
    await app.refreshStaffAgenda();
    expect(calls, 0);
    expect(app.agenda, isEmpty);
    expect(app.staffAgendaError, contains('óptica asignada'));
  });

  test('agenda descarta respuestas antiguas y excluye citas canceladas',
      () async {
    final pending = Completer<http.Response>();
    final app = staffController((request) async {
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
    final old = app.refreshStaffAgenda(date: DateTime(2026, 11, 11));
    await app.refreshStaffAgenda(date: DateTime(2026, 11, 12));
    pending.complete(staffResponse([]));
    await old;
    expect(app.agenda.single.appointmentId, 'appointment-1');
    expect(app.agendaDate, DateTime(2026, 11, 12));
    expect(app.agenda.single.name, 'Camila Paz Morales');
  });

  test('error de registro no crea un paciente local', () async {
    final app = staffController(
        (_) async => staffResponse({'message': 'Correo ya registrado'}, 409));
    expect(
        await app.registerStaffPatient(
            name: 'Camila',
            email: 'camila@example.test',
            phone: '987654321',
            dni: '12345678'),
        isNull);
    expect(app.staffPatients, isEmpty);
    expect(app.staffPatientSaveError, 'Correo ya registrado');
  });

  test('logout descarta directorio en vuelo y no restaura datos de la cuenta',
      () async {
    final pending = Completer<http.Response>();
    final app = staffController((_) => pending.future);
    final loading = app.refreshStaffPatients();
    await app.logout();
    pending.complete(staffResponse([staffPatientFixture]));
    await loading;
    expect(app.staffPatients, isEmpty);
    expect(app.staffPatient('patient-1'), isNull);
    expect(app.agenda, isEmpty);
  });

  test('booking de personal usa paciente elegido y recarga horarios ante 409',
      () async {
    var posts = 0;
    final start = DateTime.now().add(const Duration(days: 2));
    final app = staffController((request) async {
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
    await app.prepareStaffBooking(patientId: 'patient-1');
    app.selectStaffBooking(slotId: 'slot-1');
    expect(await app.confirmStaffBooking(), isFalse);
    expect(posts, 1);
    expect(app.staffBookingSlotId, isNull);
    expect(app.staffBookingError, 'Horario ocupado');
    expect(app.staffBookingSlots, hasLength(1));
    expect(app.session?.patientId, 'staff-1');
  });
}
