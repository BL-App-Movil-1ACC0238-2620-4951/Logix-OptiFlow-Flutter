import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/data/repositories/catalog_repository_impl.dart';

const frameFixture = <String, Object>{
  'id': 'model-uuid',
  'sku': 'RX 42',
  'name': 'Montura real',
  'material': 'Titanio',
  'shape': 'Redonda',
  'color': 'Negro',
  'price': 299.95,
  'currency': 'PEN',
};
const stockFixture = <String, Object>{
  'id': 'inventory-1',
  'opticalStoreId': 'store-1',
  'stocks': [
    {
      'frameModelId': 'model-uuid',
      'sku': 'RX 42',
      'name': 'Montura real',
      'price': 299.95,
      'quantity': 3,
      'minimumStock': 5,
      'low': true
    }
  ],
};
const movementFixture = <String, Object>{
  'id': 'movement-1',
  'sku': 'RX 42',
  'frameModelName': 'Montura real',
  'type': 'IN',
  'reason': 'REPLENISHMENT',
  'quantity': 4,
  'createdAt': '2026-11-01T15:00:00Z',
};

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> expectStatus(Future<Object?> action, int status) async {
  try {
    await action;
  } on ApiException catch (error) {
    check(error.statusCode == status,
        'Expected HTTP $status, got ${error.statusCode}');
    return;
  }
  throw StateError('Expected HTTP $status to fail');
}

// No Flutter engine or sockets are needed: these checks can also run with Dart.
Future<void> runInventoryApiChecks() async {
  final requests = <http.Request>[];
  final api = OptiFlowApi(
      baseUrl: 'http://localhost:8080/api/v1/',
      client: MockClient((request) async {
        requests.add(request);
        check(request.headers['Authorization'] == 'Bearer token',
            'Inventory requests must send the active token');
        final path = request.url.pathSegments;
        if (request.method == 'PATCH') {
          check(path[path.length - 2] == 'RX 42' && path.last == 'price',
              'PATCH must use the encoded SKU');
          check(jsonDecode(request.body)['price'] == 349.90,
              'PATCH must preserve the decimal price');
          return jsonResponse({...frameFixture, 'price': 349.90});
        }
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map;
          check(
              path.last == 'replenishments', 'Use the replenishment endpoint');
          check(
              body['opticalStoreId'] == 'store-1' &&
                  body['supplierId'] == 'supplier-1' &&
                  body['sku'] == 'RX 42' &&
                  body['quantity'] == 4,
              'Replenishment must send all real identifiers');
          check(!body.containsKey('minimumStock') || body['minimumStock'] == 0,
              'Zero minimum must be preserved and omitted minimum must stay absent');
          return jsonResponse(movementFixture, 201);
        }
        if (path.last == 'frames') return jsonResponse([frameFixture]);
        if (path.last == 'RX 42') {
          check(request.url.queryParameters['opticalStoreId'] == 'store-1',
              'SKU lookup must scope stock to the assigned store');
          return jsonResponse(
              {...frameFixture, 'quantity': 3, 'minimumStock': 5});
        }
        if (path.last == 'stock') {
          check(request.url.queryParameters['opticalStoreId'] == 'store-1',
              'Stock query must use the assigned store');
          return jsonResponse(stockFixture);
        }
        if (path.last == 'suppliers') {
          return jsonResponse([
            {'id': 'supplier-1', 'name': 'Proveedor real', 'contact': 'Lima'}
          ]);
        }
        if (path.last == 'movements') {
          final query = request.url.queryParameters;
          check(
              query['sku'] == 'RX 42' &&
                  query['from'] == '2026-11-01' &&
                  query['to'] == '2026-11-30',
              'Movement filters must send SKU and ISO dates');
          return jsonResponse([movementFixture]);
        }
        throw StateError(
            'Unexpected inventory request: ${request.method} ${request.url}');
      }));
  api.token = 'token';
  final catalog = CatalogRepositoryImpl(api);
  final frames = await catalog.frames();
  check(frames.single.id == 'RX 42', 'Routes must use SKU, not model UUID');
  check(frames.single.price == 299.95 && frames.single.fromPrice == 'S/ 299.95',
      'Catalog must preserve cents and PEN currency');
  check(!frames.single.stockKnown && frames.single.image.isEmpty,
      'Catalog must not invent stock or a product photograph');
  final frame = await catalog.frame('RX 42', opticalStoreId: 'store-1');
  check(frame.stockKnown && frame.stock == 3 && frame.minimumStock == 5,
      'SKU detail must use server stock');
  final stock = await api.inventoryStock('store-1');
  check(stock.stocks.single.quantity == 3 && stock.stocks.single.low,
      'Stock threshold must come from the API');
  check((await api.suppliers()).single.id == 'supplier-1',
      'Suppliers must come from the API');
  check((await catalog.updatePrice('RX 42', 349.90)).price == 349.90,
      'Price update must use the server result');
  final movement = await api.replenishStock(
      opticalStoreId: 'store-1',
      sku: 'RX 42',
      supplierId: 'supplier-1',
      quantity: 4,
      minimumStock: 0);
  check(movement.id == 'movement-1' && movement.quantity == 4,
      'Replenishment must return the registered movement');
  await api.replenishStock(
      opticalStoreId: 'store-1',
      sku: 'RX 42',
      supplierId: 'supplier-1',
      quantity: 4);
  final history = await api.stockMovements(
      opticalStoreId: 'store-1',
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 30),
      sku: 'RX 42');
  check(history.single.sku == 'RX 42' && history.single.type == 'IN',
      'Movement history must retain its SKU and direction');
  check(requests.length == 8, 'Unexpected extra inventory requests');

  for (final status in [403, 404]) {
    final failing = OptiFlowApi(
        client: MockClient(
            (_) async => jsonResponse({'message': 'Denied'}, status)));
    failing.token = 'token';
    await expectStatus(failing.frameModel('UNKNOWN'), status);
    check(failing.token == 'token',
        'A permission or missing SKU error must not log out');
  }
  final empty = OptiFlowApi(client: MockClient((_) async => jsonResponse([])));
  check((await CatalogRepositoryImpl(empty).frames()).isEmpty,
      'Empty catalogs must stay empty');
}

Future<void> main() async {
  await runInventoryApiChecks();
  print('Inventory API checks passed.');
}
