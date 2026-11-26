import 'package:flutter_test/flutter_test.dart';
import 'support/test_apis.dart';
import 'package:http/testing.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
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
    final app = await testController(MockClient((_) async {
      requests++;
      return clinicalResponse({});
    }));
    app.sessionVm.session = const PatientSession(
        patientId: 'staff',
        name: 'Asesor',
        email: 'staff@example.test',
        token: 'token',
        role: UserRole.salesAdvisor);
    await app.careVm.start('patient-1', 'appointment-1');
    expect(app.careVm.flow, isNull);
    expect(requests, 0);
    app.dispose();
  });

  test('logout descarta la atención de la cuenta anterior', () async {
    final server = ClinicalServer();
    (await setupTestDependencies(MockClient(server.respond))).token =
        'staff-token';
    final app = TestApp();
    app.sessionVm.session = const PatientSession(
        patientId: 'staff',
        name: 'Optometrista',
        email: 'staff@example.test',
        token: 'staff-token',
        role: UserRole.optometrist);
    await app.careVm.start('patient-1', 'appointment-1');
    final previous = app.careVm.flow!;
    await app.sessionVm.logout();
    expect(app.careVm.flow, isNull);
    expect(previous.active, isFalse);
    expect(await previous.saveExamination(), isFalse);
    expect(server.examinations, 0);
    app.dispose();
  });
}
