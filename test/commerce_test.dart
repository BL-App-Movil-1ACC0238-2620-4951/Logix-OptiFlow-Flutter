import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/di/dependencies.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/patient_session.dart';
import 'package:logix_optiflow/domain/entities/user_role.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/commerce_flow_checks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('cotizaciones, ventas y recuperación de cobros según Movile', runCommerceFlowChecks);
  test('roles sin permisos no cargan cotizaciones ni ventas', () async {
    var requests = 0;
    final app = OptiFlowController(dependencies: AppDependencies(api: OptiFlowApi(client: MockClient((_) async { requests++; return commerceResponse({}); }))));
    for (final role in [UserRole.patient, UserRole.optometrist, UserRole.technician]) {
      app.session = PatientSession(patientId: 'account', name: 'Cuenta', email: 'account@example.test', token: 'token', role: role);
      await app.startQuote('patient-1'); await app.openStaffSale('patient-1', saleId: 'sale-1');
      expect(app.quoteFlow, isNull); expect(app.saleFlow, isNull);
    }
    expect(requests, 0); app.dispose();
  });
  test('logout descarta el flujo comercial anterior', () async {
    final server = CommerceServer()..seed();
    final api = OptiFlowApi(client: MockClient(server.respond))..token = 'staff-token';
    final app = OptiFlowController(dependencies: AppDependencies(api: api));
    app.session = const PatientSession(patientId: 'staff', name: 'Asesor', email: 'staff@example.test', token: 'staff-token', role: UserRole.salesAdvisor, opticalStoreId: 'store-1');
    await app.startQuote('patient-1'); await app.openStaffSale('patient-1', saleId: 'sale-1');
    final quote = app.quoteFlow!, sale = app.saleFlow!;
    await app.logout();
    expect(app.quoteFlow, isNull); expect(app.saleFlow, isNull);
    expect(quote.active, isFalse); expect(sale.active, isFalse);
    await sale.payCashAndClose(); expect(server.payments, 0); app.dispose();
  });
}
