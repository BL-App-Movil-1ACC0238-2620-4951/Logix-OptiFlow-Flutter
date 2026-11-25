import 'package:flutter_test/flutter_test.dart';
import 'support/test_apis.dart';
import 'package:http/testing.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/commerce_flow_checks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('cotizaciones, ventas y recuperación de cobros según Movile', runCommerceFlowChecks);
  test('roles sin permisos no cargan cotizaciones ni ventas', () async {
    var requests = 0;
    final app = await testController(MockClient((_) async { requests++; return commerceResponse({}); }));
    for (final role in [UserRole.patient, UserRole.optometrist, UserRole.technician]) {
      app.sessionVm.session = PatientSession(patientId: 'account', name: 'Cuenta', email: 'account@example.test', token: 'token', role: role);
      await app.quoteVm.start('patient-1'); await app.saleVm.open('patient-1', saleId: 'sale-1');
      expect(app.quoteVm.flow, isNull); expect(app.saleVm.flow, isNull);
    }
    expect(requests, 0); app.dispose();
  });
  test('logout descarta el flujo comercial anterior', () async {
    final server = CommerceServer()..seed();
    (await setupTestDependencies(MockClient(server.respond))).token = 'staff-token';
    final app = TestApp();
    app.sessionVm.session = const PatientSession(patientId: 'staff', name: 'Asesor', email: 'staff@example.test', token: 'staff-token', role: UserRole.salesAdvisor, opticalStoreId: 'store-1');
    await app.quoteVm.start('patient-1'); await app.saleVm.open('patient-1', saleId: 'sale-1');
    final quote = app.quoteVm.flow!, sale = app.saleVm.flow!;
    await app.sessionVm.logout();
    expect(app.quoteVm.flow, isNull); expect(app.saleVm.flow, isNull);
    expect(quote.active, isFalse); expect(sale.active, isFalse);
    await sale.payCashAndClose(); expect(server.payments, 0); app.dispose();
  });
}
