import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/data/repositories/clinical_repository_impl.dart';
import 'package:logix_optiflow/domain/entities/clinical_forms.dart';
import 'package:logix_optiflow/presentation/state/clinical_care_flow.dart';

void clinicalCheck(bool value, String message) {
  if (!value) throw StateError(message);
}

http.Response clinicalResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

class ClinicalServer {
  String appointmentStatus = 'CONFIRMED';
  String recordStatus = 'PENDING';
  Map<String, dynamic>? history;
  Map<String, dynamic>? prescription;
  String observations = '';
  int examinations = 0, histories = 0, prescriptions = 0, completions = 0;
  int completionFailures = 0;
  bool examinationConflict = false;
  bool prescriptionConflict = false;
  bool wrongAppointmentPatient = false;
  bool wrongRecordPatient = false;
  bool incompletePrescriptionResponse = false;
  Completer<http.Response>? pendingExamination;

  Map<String, Object?> get appointment => {
        'id': 'appointment-1',
        'patientId': wrongAppointmentPatient ? 'other-patient' : 'patient-1',
        'opticalStoreId': 'store-1',
        'timeSlotId': 'slot-1',
        'status': appointmentStatus,
        'startDateTime': '2026-11-12T15:00:00Z',
        'endDateTime': '2026-11-12T15:30:00Z',
      };
  Map<String, Object?> get record => {
        'id': 'record-1',
        'patientId': wrongRecordPatient ? 'other-patient' : 'patient-1',
        'appointmentId': 'appointment-1',
        'status': recordStatus,
        'examinationDate':
            recordStatus == 'PENDING' ? null : '2026-11-12T15:00:00Z',
        'observations': observations,
        'medicalHistory': history,
        'prescription': prescription,
      };

  Future<http.Response> respond(http.Request request) async {
    clinicalCheck(request.headers['Authorization'] == 'Bearer staff-token',
        'All clinical requests must keep staff authentication');
    final path = request.url.path;
    if (request.method == 'GET') {
      if (path.endsWith('/patients/patient-1')) {
        return clinicalResponse({
          'id': 'patient-1',
          'name': 'Paciente de prueba',
          'email': 'patient@example.test',
          'phone': '999888777'
        });
      }
      if (path.endsWith('/patients/patient-1/appointments')) {
        return clinicalResponse([appointment]);
      }
      if (path.endsWith('/patients/patient-1/clinical-records')) {
        return clinicalResponse([record]);
      }
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    if (request.method == 'POST' && path.endsWith('/clinical-records')) {
      examinations++;
      clinicalCheck(
          body['patientId'] == 'patient-1' &&
              body['appointmentId'] == 'appointment-1',
          'Examination must retain patient and appointment identity');
      observations = body['observations'] as String? ?? '';
      recordStatus = 'OPEN';
      if (pendingExamination != null) return pendingExamination!.future;
      if (examinationConflict) {
        return clinicalResponse({'message': 'Ya registrada'}, 409);
      }
      return clinicalResponse(record, 201);
    }
    if (request.method == 'PUT' &&
        path.endsWith('/clinical-records/record-1/medical-history')) {
      histories++;
      clinicalCheck(
          body['allergies'] is List &&
              body['previousConditions'] is List &&
              body.containsKey('familyOcularHistory'),
          'History must use the Movile request fields');
      history = body;
      return clinicalResponse(record);
    }
    if (request.method == 'POST' &&
        path.endsWith('/clinical-records/record-1/prescription')) {
      prescriptions++;
      clinicalCheck(
          body['sphereOD'] is num &&
              body['cylinderOD'] is num &&
              body['axisOD'] is int &&
              body['sphereOS'] is num &&
              body['axisOS'] is int,
          'Prescription fields must be numeric with integer axes');
      prescription = {...body, 'clinicalRecordId': 'record-1'};
      recordStatus = 'CLOSED';
      if (prescriptionConflict) {
        return clinicalResponse({'message': 'Receta ya guardada'}, 409);
      }
      return clinicalResponse(
          incompletePrescriptionResponse
              ? {'clinicalRecordId': 'record-1'}
              : prescription!,
          201);
    }
    if (request.method == 'PATCH' &&
        path.endsWith('/appointments/appointment-1/status')) {
      completions++;
      clinicalCheck(prescription != null && body['status'] == 'COMPLETED',
          'Only close this appointment after the prescription is stored');
      if (completionFailures > 0) {
        completionFailures--;
        return clinicalResponse({'message': 'Cierre no disponible'}, 503);
      }
      appointmentStatus = 'COMPLETED';
      return clinicalResponse(appointment);
    }
    throw StateError('Unexpected clinical request: ${request.method} $path');
  }

  ClinicalCareFlow flow(
      {bool Function()? isActive, void Function()? onChanged}) {
    final api = OptiFlowApi(client: MockClient(respond))..token = 'staff-token';
    return ClinicalCareFlow(
        repository: ClinicalRepositoryImpl(api),
        patientId: 'patient-1',
        appointmentId: 'appointment-1',
        isActive: isActive,
        onChanged: onChanged);
  }
}

PrescriptionForm validForm() => PrescriptionForm(
    sphereOD: '-1,75',
    cylinderOD: '-0.50',
    axisOD: '180',
    sphereOS: '-2.00',
    cylinderOS: '-0.75',
    axisOS: '175',
    addition: '+2.00',
    treatment: 'Antirreflejo',
    recommendedFrameType: 'Acetato');
Future<void> toPrescription(ClinicalCareFlow flow) async {
  await flow.load();
  clinicalCheck(flow.loadError == null, 'Clinical context must load');
  flow.observations = 'Evaluación de prueba';
  clinicalCheck(await flow.saveExamination(), 'Examination must be saved');
  flow.allergies = 'Polen; Polen, Penicilina';
  flow.previousConditions = 'Diabetes\nHipertensión';
  flow.familyHistory = 'Antecedentes de prueba';
  clinicalCheck(await flow.saveHistory(), 'History must be saved');
  flow.prescription = validForm();
}

Future<void> runClinicalFlowChecks() async {
  // Full workflow through the production repository, DTOs and HTTP client.
  final normal = ClinicalServer();
  final flow = normal.flow();
  await toPrescription(flow);
  clinicalCheck(
      flow.step == CareStep.prescription &&
          normal.history!['allergies'].length == 2,
      'Antecedents must deduplicate comma/semicolon lists');
  clinicalCheck(flow.back() && flow.step == CareStep.history,
      'Back must allow reviewing antecedents');
  clinicalCheck(
      await flow.saveHistory(), 'Reviewed history must be saved using PUT');
  clinicalCheck(await flow.savePrescriptionAndFinish(),
      'The full clinical workflow must finish');
  clinicalCheck(
      flow.step == CareStep.done &&
          normal.examinations == 1 &&
          normal.prescriptions == 1 &&
          normal.completions == 1,
      'Only one exam and prescription may be posted');
  clinicalCheck(
      normal.prescription!['sphereOD'] == -1.75 &&
          normal.prescription!['addition'] == 2,
      'Decimal comma and optional addition must match Movile');
  clinicalCheck(
      !await flow.savePrescriptionAndFinish() && normal.prescriptions == 1,
      'Done must not create another prescription');

  // Reopening the same appointment restores the saved steps instead of reposting.
  final resumed = normal.flow();
  await resumed.load();
  clinicalCheck(resumed.step == CareStep.done && resumed.prescriptionSaved,
      'Completed appointment must reopen as done');
  final historyOnly = ClinicalServer()..recordStatus = 'OPEN';
  final review = historyOnly.flow();
  await review.load();
  clinicalCheck(review.step == CareStep.history,
      'An existing examination resumes at history');
  historyOnly.history = {
    'allergies': <String>[],
    'previousConditions': <String>[],
    'familyOcularHistory': null
  };
  final rxStep = historyOnly.flow();
  await rxStep.load();
  clinicalCheck(rxStep.step == CareStep.prescription,
      'Existing antecedents resume at prescription');

  // Saving the prescription and completing the appointment are separate writes.
  final partial = ClinicalServer()..completionFailures = 1;
  final partialFlow = partial.flow();
  await toPrescription(partialFlow);
  clinicalCheck(!await partialFlow.savePrescriptionAndFinish(),
      'Failed close must not display done');
  clinicalCheck(
      partialFlow.prescriptionSaved &&
          partialFlow.step == CareStep.prescription &&
          partialFlow.error!.contains('La receta se guardó'),
      'Partial save must preserve its server confirmation');
  clinicalCheck(await partialFlow.savePrescriptionAndFinish(),
      'Retry must finish the appointment');
  clinicalCheck(partial.prescriptions == 1 && partial.completions == 2,
      'Retry must PATCH only, not POST a second prescription');

  final conflict = ClinicalServer()..examinationConflict = true;
  final conflictingFlow = conflict.flow();
  await conflictingFlow.load();
  clinicalCheck(
      await conflictingFlow.saveExamination() &&
          conflictingFlow.step == CareStep.history,
      '409 must find and resume the existing examination');
  clinicalCheck(conflict.examinations == 1,
      'Conflict recovery must not issue another examination POST');
  final rxConflict = ClinicalServer()..prescriptionConflict = true;
  final rxConflictFlow = rxConflict.flow();
  await toPrescription(rxConflictFlow);
  clinicalCheck(
      await rxConflictFlow.savePrescriptionAndFinish() &&
          rxConflict.prescriptions == 1,
      'An already stored prescription must be recovered on 409');

  final cancelled = ClinicalServer()..appointmentStatus = 'CANCELLED';
  final cancelledFlow = cancelled.flow();
  await cancelledFlow.load();
  clinicalCheck(
      cancelledFlow.loadError != null &&
          !await cancelledFlow.saveExamination() &&
          cancelled.examinations == 0,
      'Cancelled appointments must reject clinical writes');
  final wrong = ClinicalServer()..wrongAppointmentPatient = true;
  final wrongFlow = wrong.flow();
  await wrongFlow.load();
  clinicalCheck(
      wrongFlow.loadError != null && !await wrongFlow.saveExamination(),
      'An appointment for another patient must not open');
  final wrongRecord = ClinicalServer()..wrongRecordPatient = true;
  final wrongRecordFlow = wrongRecord.flow();
  await wrongRecordFlow.load();
  clinicalCheck(wrongRecordFlow.loadError != null,
      'A record for another patient must not be reused');

  // Double click and logout during an outstanding request must not advance state.
  final pendingServer = ClinicalServer()
    ..pendingExamination = Completer<http.Response>();
  final pendingFlow = pendingServer.flow();
  await pendingFlow.load();
  final firstSave = pendingFlow.saveExamination();
  clinicalCheck(!await pendingFlow.saveExamination(),
      'A second click while saving must be ignored');
  await Future<void>.delayed(Duration.zero);
  pendingServer.pendingExamination!
      .complete(clinicalResponse(pendingServer.record, 201));
  clinicalCheck(await firstSave && pendingServer.examinations == 1,
      'Only one examination request may run');
  var authorized = true;
  var changes = 0;
  final logoutServer = ClinicalServer()
    ..pendingExamination = Completer<http.Response>();
  final logoutFlow =
      logoutServer.flow(isActive: () => authorized, onChanged: () => changes++);
  await logoutFlow.load();
  final saving = logoutFlow.saveExamination();
  await Future<void>.delayed(Duration.zero);
  authorized = false;
  final priorChanges = changes;
  logoutServer.pendingExamination!
      .complete(clinicalResponse(logoutServer.record, 201));
  clinicalCheck(
      !await saving && changes == priorChanges && logoutServer.completions == 0,
      'A late response must not mutate or notify a different session');

  final malformed = ClinicalServer()..incompletePrescriptionResponse = true;
  final malformedFlow = malformed.flow();
  await toPrescription(malformedFlow);
  clinicalCheck(
      !await malformedFlow.savePrescriptionAndFinish() &&
          malformed.completions == 0,
      'A malformed prescription response must not silently close the appointment');

  void rejects(void Function() action) {
    try {
      action();
    } on FormatException {
      return;
    }
    throw StateError('Expected invalid clinical fields to be rejected');
  }

  rejects(() => (validForm()..sphereOD = '31').validate());
  rejects(() => (validForm()..cylinderOS = '-11').validate());
  rejects(() => (validForm()..axisOD = '181').validate());
  rejects(() => (validForm()..axisOD = '12.5').validate());
  rejects(() => (validForm()..addition = '4.1').validate());
  rejects(() => (validForm()..sphereOS = 'NaN').validate());
  rejects(() => (validForm()..treatment = 'x' * 256).validate());
  rejects(() => validateMedicalHistory(
      List.generate(21, (i) => 'allergy-$i').join(','), '', ''));
  rejects(() => validateMedicalHistory('x' * 101, '', ''));
  rejects(() => validateMedicalHistory('', '', 'x' * 1001));
  final oversize = ClinicalServer();
  final oversizeFlow = oversize.flow();
  await oversizeFlow.load();
  oversizeFlow.observations = 'x' * 501;
  clinicalCheck(
      !await oversizeFlow.saveExamination() && oversize.examinations == 0,
      'Invalid observations must not make a write request');
}

Future<void> main() async {
  await runClinicalFlowChecks();
  print(
      'Clinical workflow, HTTP contracts and recovery checks passed (simulated backend).');
}
