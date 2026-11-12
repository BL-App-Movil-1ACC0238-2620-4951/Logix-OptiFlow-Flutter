import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logix_optiflow/core/di/dependencies.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/models.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';

http.Response response(Object value, [int status = 200]) => http.Response(
      jsonEncode(value),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const store = {
  'id': 'store-1',
  'name': 'Óptica real',
  'address': 'Lima',
  'phone': '999888777',
  'rating': 4.5,
  'status': 'ACTIVE'
};
final futureSunday = DateTime.now().add(const Duration(days: 21));
final slotDate = DateTime(futureSunday.year, futureSunday.month,
    futureSunday.day + (7 - futureSunday.weekday), 14);

Map<String, Object> slot(
    {String id = 'slot-1',
    String status = 'AVAILABLE',
    String storeId = 'store-1',
    DateTime? start}) {
  final when = start ?? slotDate;
  return {
    'id': id,
    'opticalStoreId': storeId,
    'startDateTime': when.toUtc().toIso8601String(),
    'endDateTime':
        when.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
    'status': status
  };
}

Map<String, Object> appointment(
        {String id = 'new-appointment', String status = 'CONFIRMED'}) =>
    {
      'id': id,
      'patientId': 'patient-1',
      'opticalStoreId': 'store-1',
      'timeSlotId': 'slot-1',
      'startDateTime': slotDate.toUtc().toIso8601String(),
      'endDateTime':
          slotDate.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
      'status': status,
    };

OptiFlowController controller(
    Future<http.Response> Function(http.Request) handler) {
  final api = OptiFlowApi(client: MockClient(handler));
  final app = OptiFlowController(dependencies: AppDependencies(api: api));
  app.session = const PatientSession(
      patientId: 'patient-1',
      name: 'Paciente',
      email: 'patient@optiflow.pe',
      token: 'token');
  api.token = 'token';
  addTearDown(app.dispose);
  return app;
}

Future<void> chooseSlot(OptiFlowController app) async {
  await app.prepareBooking('store-1');
  await app.continueFromStore();
  app.selectSlot(app.slots.first);
  expect(app.continueFromDate(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin ópticas o con error no ofrece reservas de demostración', () async {
    for (final status in [200, 503]) {
      var posts = 0;
      final app = controller((request) async {
        if (request.method == 'POST') posts++;
        return response(
            status == 200 ? [] : {'message': 'Servidor no disponible'}, status);
      });
      await app.prepareBooking(null);
      expect(app.bookingStores, isEmpty);
      expect(app.bookingError, isNotNull);
      app.bookingStep = 3;
      expect(await app.confirmBooking(), isFalse);
      expect(posts, 0);
      expect(app.bookingAppointment, isNull);
    }
  });

  test(
      'solo ofrece horarios futuros disponibles de la óptica, incluso domingos',
      () async {
    final app =
        controller((request) async => request.url.path.endsWith('/time-slots')
            ? response([
                slot(),
                slot(id: 'booked', status: 'BOOKED'),
                slot(id: 'other', storeId: 'store-2'),
                slot(id: 'past', start: DateTime.utc(2000))
              ])
            : response([store]));
    await app.prepareBooking('store-1');
    await app.continueFromStore();
    expect(app.slots, hasLength(1));
    expect(app.selectedDate?.weekday, DateTime.sunday);
    expect(app.hasSlots(app.weekStart.add(const Duration(days: 6))), isTrue);
    expect(app.slots.first.durationMinutes, 30);
  });

  test('error al cargar horarios conserva lista vacía sin inventar horarios',
      () async {
    final app = controller((request) async =>
        request.url.path.endsWith('/time-slots')
            ? response({'message': 'No se pudo consultar disponibilidad'}, 503)
            : response([store]));
    await app.prepareBooking('store-1');
    await app.continueFromStore();
    expect(app.slots, isEmpty);
    expect(app.bookingError, contains('disponibilidad'));
    expect(app.continueFromDate(), isFalse);
  });

  test(
      'reserva real envía IDs y token, evita doble envío y actualiza Mis citas',
      () async {
    final pending = Completer<http.Response>();
    var posts = 0;
    final app = controller((request) async {
      if (request.method == 'POST') {
        posts++;
        expect(request.headers['Authorization'], 'Bearer token');
        expect(jsonDecode(request.body), {
          'patientId': 'patient-1',
          'opticalStoreId': 'store-1',
          'timeSlotId': 'slot-1'
        });
        return pending.future;
      }
      return request.url.path.endsWith('/time-slots')
          ? response([slot()])
          : response([store]);
    });
    await chooseSlot(app);
    final booking = app.confirmBooking();
    expect(await app.confirmBooking(), isFalse);
    pending.complete(response(appointment(), 201));
    expect(await booking, isTrue);
    expect(posts, 1);
    expect(app.bookingStep, 4);
    expect(app.appointments.single.id, 'new-appointment');
    expect(app.appointments.single.fromApi, isTrue);
  });

  test('un conflicto 409 pide otro horario y no muestra reserva exitosa',
      () async {
    final app = controller((request) async {
      if (request.method == 'POST') {
        return response({'message': 'Slot unavailable'}, 409);
      }
      return request.url.path.endsWith('/time-slots')
          ? response([slot()])
          : response([store]);
    });
    await chooseSlot(app);
    expect(await app.confirmBooking(), isFalse);
    expect(app.bookingStep, 2);
    expect(app.selectedSlot, isNull);
    expect(app.bookingAppointment, isNull);
    expect(app.appointments, isEmpty);
  });

  test('cancelación PATCH solo cambia estado después de respuesta exitosa',
      () async {
    var allowCancel = false;
    final app = controller((request) async {
      if (request.method == 'PATCH') {
        expect(request.url.path, '/api/v1/appointments/original/status');
        expect(jsonDecode(request.body), {'status': 'CANCELLED'});
        return allowCancel
            ? response(appointment(id: 'original', status: 'CANCELLED'))
            : response({'message': 'No autorizado'}, 403);
      }
      return request.url.path.endsWith('/appointments')
          ? response([appointment(id: 'original')])
          : response([store]);
    });
    await app.refreshAppointments();
    expect(await app.cancelAppointment('original'), isFalse);
    expect(app.appointments.single.status, AppointmentStatus.confirmed);
    allowCancel = true;
    expect(await app.cancelAppointment('original'), isTrue);
    expect(app.appointments.single.status, AppointmentStatus.cancelled);
    expect(app.upcoming, isEmpty);
  });

  test(
      'reprogramación parcialmente fallida reintenta cancelar sin duplicar reserva',
      () async {
    var posts = 0;
    var patches = 0;
    final app = controller((request) async {
      if (request.method == 'POST') {
        posts++;
        return response(appointment(), 201);
      }
      if (request.method == 'PATCH') {
        patches++;
        return patches == 1
            ? response({'message': 'Temporary error'}, 500)
            : response(appointment(id: 'original', status: 'CANCELLED'));
      }
      if (request.url.path.endsWith('/time-slots')) return response([slot()]);
      if (request.url.path.endsWith('/appointments')) {
        return response([appointment(id: 'original')]);
      }
      return response([store]);
    });
    await app.prepareBooking(null, rescheduleId: 'original');
    await app.continueFromStore();
    app.selectSlot(app.slots.first);
    app.continueFromDate();
    expect(await app.confirmBooking(), isFalse);
    expect(app.bookingStep, 3);
    expect(app.bookingAppointment?.id, 'new-appointment');
    expect(app.bookingError, contains('nueva cita está reservada'));
    expect(await app.confirmBooking(), isTrue);
    expect(posts, 1);
    expect(patches, 2);
    expect(
        app.appointmentById('original')?.status, AppointmentStatus.cancelled);
    expect(app.bookingStep, 4);
  });

  test('búsquedas fuera de orden no reemplazan el resultado más reciente',
      () async {
    final older = Completer<http.Response>();
    final app = controller(
        (request) async => request.url.queryParameters['name'] == 'anterior'
            ? older.future
            : response([
                {...store, 'name': 'Resultado nuevo'}
              ]));
    app.setSearchQuery('anterior');
    final previous = app.searchStores();
    app.setSearchQuery('nueva');
    await app.searchStores();
    older.complete(response([
      {...store, 'name': 'Resultado viejo'}
    ]));
    await previous;
    expect(app.searchResults.single.name, 'Resultado nuevo');
    expect(app.searchLoading, isFalse);
  });

  test('cerrar sesión mientras carga disponibilidad descarta la respuesta',
      () async {
    final pending = Completer<http.Response>();
    final app = controller((request) async =>
        request.url.path.endsWith('/time-slots')
            ? pending.future
            : response([store]));
    await app.prepareBooking('store-1');
    final loading = app.continueFromStore();
    await app.logout();
    pending.complete(response([slot()]));
    await loading;
    expect(app.slots, isEmpty);
    expect(app.bookingStores, isEmpty);
    expect(app.bookingAppointment, isNull);
  });

  test('respuesta antigua de listado no borra una reserva recién confirmada',
      () async {
    final pending = Completer<http.Response>();
    final app = controller((request) async {
      if (request.method == 'POST') return response(appointment(), 201);
      if (request.url.path.endsWith('/appointments')) return pending.future;
      return request.url.path.endsWith('/time-slots')
          ? response([slot()])
          : response([store]);
    });
    await chooseSlot(app);
    final oldList = app.refreshAppointments();
    expect(await app.confirmBooking(), isTrue);
    pending.complete(response([]));
    await oldList;
    expect(app.appointments.single.id, 'new-appointment');
  });
}
