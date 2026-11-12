import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/data/models/staff_dto.dart';
import 'package:logix_optiflow/domain/entities/agenda_item.dart';
import 'package:logix_optiflow/domain/entities/store_time.dart';
import 'package:logix_optiflow/presentation/mappers/staff_view_mapper.dart';

const staffPatientFixture = <String, Object>{
  'id': 'patient-1',
  'name': 'Camila Paz Morales',
  'email': 'camila@example.test',
  'phone': '987654321',
  'birthDate': '1990-05-24',
  'createdAt': '2026-11-01T15:00:00Z',
};
const staffAppointmentFixture = <String, Object>{
  'id': 'appointment-1',
  'patientId': 'patient-1',
  'opticalStoreId': 'store-1',
  'timeSlotId': 'slot-1',
  'status': 'CONFIRMED',
  'startDateTime': '2026-11-12T15:00:00Z',
  'endDateTime': '2026-11-12T15:30:00Z',
};
const staffOrderFixture = <String, Object>{
  'id': 'order-1',
  'patientId': 'patient-1',
  'status': 'IN_WORKSHOP',
  'estimatedDeliveryDate': '2026-11-20',
  'delayed': false,
  'createdAt': '2026-11-01T15:00:00Z',
  'lenses': [
    {'specifications': 'Monofocal'}
  ],
};

http.Response staffResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
void verify(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> runStaffApiChecks() async {
  final api = OptiFlowApi(client: MockClient((request) async {
    final path = request.url.path;
    if (request.method == 'POST') {
      verify(path == '/api/v1/patients',
          'Staff registration must use POST /patients');
      final body = jsonDecode(request.body) as Map;
      verify(
          body['password'] == '12345678' && body['birthDate'] == '1990-05-24',
          'DNI temporary password and ISO birth date must match Movile');
      verify(
          body['name'] == 'Camila Paz Morales' &&
              body['email'] == 'camila@example.test' &&
              body['phone'] == '987654321',
          'Registration must preserve patient fields');
      return staffResponse(staffPatientFixture, 201);
    }
    verify(request.headers['Authorization'] == 'Bearer staff-token',
        'Staff queries require the staff token');
    if (path == '/api/v1/patients') return staffResponse([staffPatientFixture]);
    if (path == '/api/v1/patients/patient-1') {
      return staffResponse(staffPatientFixture);
    }
    if (path == '/api/v1/appointments') {
      verify(
          request.url.queryParameters['opticalStoreId'] == 'store-1' &&
              request.url.queryParameters['date'] == '2026-11-12',
          'Agenda must use assigned store and selected ISO date');
      return staffResponse([staffAppointmentFixture]);
    }
    if (path.endsWith('/appointments')) {
      return staffResponse([staffAppointmentFixture]);
    }
    if (path == '/api/v1/clinical-records/summary') {
      return staffResponse({'patientsWithRecords': 7});
    }
    if (path == '/api/v1/work-orders') {
      return staffResponse([staffOrderFixture]);
    }
    if (path.endsWith('/clinical-records')) {
      return staffResponse([
        {
          'id': 'record-1',
          'appointmentId': 'appointment-1',
          'status': 'COMPLETED',
          'examinationDate': '2026-11-01T15:00:00Z',
          'prescription': {
            'sphereOD': -1.75,
            'cylinderOD': -0.5,
            'axisOD': 180,
            'sphereOS': -2.0,
            'cylinderOS': -0.75,
            'axisOS': 175
          },
        }
      ]);
    }
    throw StateError('Unexpected staff endpoint: $path');
  }));
  api.token = 'staff-token';
  final patients = await api.staffPatients();
  verify(
      patients.single.email == 'camila@example.test' &&
          patients.single.initials == 'CP',
      'Directory must preserve email and initials');
  verify((await api.staffPatient('patient-1')).id == 'patient-1',
      'Patient lookup must use real id');
  await api.registerPatientByStaff(
      name: 'Camila Paz Morales',
      email: 'camila@example.test',
      phone: '987654321',
      dni: '12345678',
      birthDate: DateTime(1990, 5, 24));
  verify(api.token == 'staff-token',
      'Registering a patient must not replace the staff token');
  final agenda = await api.storeAgenda('store-1', DateTime(2026, 11, 12));
  verify(await api.patientsWithRecords() == 7,
      'Clinical summary must use backend count');
  final orders = await api.staffOrders();
  verify(
      orders.single.patientId == 'patient-1' &&
          orders.single.step == 1 &&
          orders.single.label == 'En taller',
      'Work-order summary must use Movile status order');
  final record = (await api.clinicalRecords('patient-1')).single.toEntity();
  verify(
      record.id == 'record-1' &&
          record.status == 'COMPLETED' &&
          record.prescription?.sphereOd == -1.75,
      'Record must preserve real prescription and identity');
  verify((await api.appointments('patient-1')).single.id == 'appointment-1',
      'Patient record must read own appointment list');
  final appointment = agenda.single.toEntity();
  final waiting = StaffViewMapper.agenda(appointment, 'Camila',
      now: DateTime.parse('2026-11-12T14:45:00Z'));
  verify(
      waiting.status == AgendaStatus.waiting &&
          waiting.time == '10:00' &&
          waiting.duration == '30 min',
      'Waiting window starts 15 minutes before, in Lima time');
  verify(
      StaffViewMapper.agenda(appointment, 'Camila',
                  now: DateTime.parse('2026-11-12T14:44:59Z'))
              .status ==
          AgendaStatus.confirmed,
      'Before waiting window appointment stays confirmed');
  verify(
      StaffViewMapper.agenda(appointment, 'Camila',
                  now: DateTime.parse('2026-11-12T15:30:00Z'))
              .status !=
          AgendaStatus.waiting,
      'Waiting window ends at appointment end');
  verify(
      StoreTime.day(DateTime.parse('2026-11-12T01:30:00Z')) ==
          DateTime(2026, 11, 11),
      'Midnight UTC must retain the correct Lima day');
  verify(
      StoreTime.parseBirthDate('29/02/2000', today: DateTime(2026, 11, 11)) !=
          null,
      'Valid leap birth date must be accepted');
  verify(
      StoreTime.parseBirthDate('31/02/2000') == null &&
          StoreTime.parseBirthDate('12/11/2030',
                  today: DateTime(2026, 11, 11)) ==
              null,
      'Invalid and future births must be rejected');
  verify(
      StaffDto.patient(staffPatientFixture, today: DateTime(2026, 5, 23)).age ==
              35 &&
          StaffDto.patient(staffPatientFixture, today: DateTime(2026, 5, 24))
                  .age ==
              36,
      'Age must change on birthday, as in Movile');
}

Future<void> main() async {
  await runStaffApiChecks();
  print('Staff API and Movile parity checks passed.');
}
