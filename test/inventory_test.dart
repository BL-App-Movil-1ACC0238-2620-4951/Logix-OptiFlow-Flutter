import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/di/dependencies.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/domain/entities/models.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/inventory_api_checks.dart';

OptiFlowController controller(
    Future<http.Response> Function(http.Request) handler,
    {UserRole role = UserRole.admin,
    String? storeId = 'store-1'}) {
  final api = OptiFlowApi(client: MockClient(handler));
  final app = OptiFlowController(dependencies: AppDependencies(api: api));
  app.session = PatientSession(
      patientId: 'user-1',
      name: 'Usuario',
      email: 'test@optiflow.pe',
      token: 'token',
      role: role,
      opticalStoreId: storeId);
  api.token = 'token';
  addTearDown(app.dispose);
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('contratos API de catálogo, SKU, precio, stock e ingresos',
      runInventoryApiChecks);

  test('inventario combina catálogo real y stock de la óptica del asesor',
      () async {
    final app = controller(
        (request) async => request.url.path.endsWith('/stock')
            ? jsonResponse(stockFixture)
            : jsonResponse([frameFixture]),
        role: UserRole.salesAdvisor);
    await app.refreshInventory();
    expect(app.inventoryError, isNull);
    expect(app.products.single.sku, 'RX 42');
    expect(app.products.single.available, 3);
    expect(app.products.single.minimumStock, 5);
    expect(app.products.single.price, 'S/ 299.95');
  });

  test('sin óptica asignada no consulta ni inventa stock', () async {
    var requests = 0;
    final app = controller((_) async {
      requests++;
      return jsonResponse(stockFixture);
    }, storeId: null);
    await app.refreshInventory();
    expect(app.inventoryError, contains('óptica asignada'));
    expect(app.products, isEmpty);
    expect(requests, 0);
  });

  test(
      'asesor no puede registrar ingresos y las cantidades inválidas no hacen POST',
      () async {
    var requests = 0;
    final advisor = controller((_) async {
      requests++;
      return jsonResponse(movementFixture);
    }, role: UserRole.salesAdvisor);
    expect(
        await advisor.replenishStock(
            sku: 'RX 42', supplierId: 'supplier-1', quantity: 4),
        isFalse);
    final admin = controller((_) async {
      requests++;
      return jsonResponse(movementFixture);
    });
    for (final quantity in [0, -2, 1001]) {
      expect(
          await admin.replenishStock(
              sku: 'RX 42', supplierId: 'supplier-1', quantity: quantity),
          isFalse);
    }
    expect(requests, 0);
  });

  test('ingreso guardado sigue siendo exitoso aunque falle recargar stock',
      () async {
    var posts = 0;
    final app = controller((request) async {
      if (request.method == 'POST') {
        posts++;
        return jsonResponse(movementFixture, 201);
      }
      if (request.url.path.endsWith('/stock')) {
        return jsonResponse({'message': 'Error de lectura'}, 503);
      }
      if (request.url.path.endsWith('/frames')) {
        return jsonResponse([frameFixture]);
      }
      return jsonResponse({...frameFixture, 'quantity': 7, 'minimumStock': 5});
    });
    expect(
        await app.replenishStock(
            sku: 'RX 42', supplierId: 'supplier-1', quantity: 4),
        isTrue);
    expect(posts, 1);
    expect(app.inventoryError, 'Error de lectura');
    expect(app.productById('RX 42')?.available, 7);
  });

  test(
      'precio actualizado conserva stock y descarta un inventario anterior en vuelo',
      () async {
    final pending = Completer<http.Response>();
    var delayStock = false;
    final app = controller((request) async {
      if (request.method == 'PATCH') {
        return jsonResponse({...frameFixture, 'price': 399.50});
      }
      if (request.url.path.endsWith('/stock')) {
        return delayStock ? pending.future : jsonResponse(stockFixture);
      }
      return jsonResponse([frameFixture]);
    });
    await app.refreshInventory();
    delayStock = true;
    final old = app.refreshInventory();
    expect(await app.updateFramePrice('RX 42', 399.50), isTrue);
    pending.complete(jsonResponse(stockFixture));
    await old;
    expect(app.productById('RX 42')?.price, 'S/ 399.50');
    expect(app.productById('RX 42')?.available, 3);
    expect(app.frameById('RX 42')?.price, 399.50);
  });

  test(
      'logout descarta catálogo pendiente y borra modelos y stock de la cuenta',
      () async {
    final pending = Completer<http.Response>();
    final app = controller((_) => pending.future, role: UserRole.patient);
    final loading = app.refreshCatalog();
    await app.logout();
    pending.complete(jsonResponse([frameFixture]));
    await loading;
    expect(app.frames, isEmpty);
    expect(app.products, isEmpty);
    expect(app.frameById('RX 42'), isNull);
  });
}
