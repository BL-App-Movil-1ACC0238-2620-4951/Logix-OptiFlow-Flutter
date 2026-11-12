import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/di/dependencies.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/patient_session.dart';
import 'package:logix_optiflow/domain/entities/user_role.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/clinical_flow_checks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('flujo clínico completo, contratos y recuperación según Movile',
      runClinicalFlowChecks);

  test('un asesor no puede iniciar el flujo clínico ni realizar solicitudes',
      () async {
    var requests = 0;
    final app = OptiFlowController(dependencies:
        AppDependencies(api: OptiFlowApi(client: MockClient((_) async {
      requests++;
      return clinicalResponse({});
    }))));
    app.session = const PatientSession(
        patientId: 'staff',
        name: 'Asesor',
        email: 'staff@example.test',
        token: 'token',
        role: UserRole.salesAdvisor);
    await app.startClinicalCare('patient-1', 'appointment-1');
    expect(app.clinicalCare, isNull);
    expect(requests, 0);
    app.dispose();
  });

  test('logout descarta la atención de la cuenta anterior', () async {
    final server = ClinicalServer();
    final api = OptiFlowApi(client: MockClient(server.respond))
      ..token = 'staff-token';
    final app = OptiFlowController(dependencies: AppDependencies(api: api));
    app.session = const PatientSession(
        patientId: 'staff',
        name: 'Optometrista',
        email: 'staff@example.test',
        token: 'staff-token',
        role: UserRole.optometrist);
    await app.startClinicalCare('patient-1', 'appointment-1');
    final previous = app.clinicalCare!;
    await app.logout();
    expect(app.clinicalCare, isNull);
    expect(previous.active, isFalse);
    expect(await previous.saveExamination(), isFalse);
    expect(server.examinations, 0);
    app.dispose();
  });
}
