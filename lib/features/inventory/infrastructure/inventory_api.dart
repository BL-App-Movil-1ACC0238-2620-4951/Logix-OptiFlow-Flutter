import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_dto.dart';

/// Monturas, stock, proveedores y movimientos (contexto Store Management & Inventory).
class InventoryApi {
  const InventoryApi(this._client);

  final ApiClient _client;

  Future<List<FrameModelDto>> frameCatalog() async => _list(await _client.get('inventory/frames'))
      .map(FrameModelDto.new).toList();

  Future<FrameModelDto> frameModel(String sku, {String? opticalStoreId}) async => FrameModelDto(
      Map<String, dynamic>.from(await _client.get('inventory/frames/${Uri.encodeComponent(sku)}', {'opticalStoreId': opticalStoreId}) as Map));

  Future<FrameModelDto> updateFramePrice(String sku, num price) async => FrameModelDto(
      Map<String, dynamic>.from(await _client.send('PATCH', 'inventory/frames/${Uri.encodeComponent(sku)}/price', {'price': price}) as Map));

  Future<StoreInventory> inventoryStock(String opticalStoreId) async => InventoryDto.stock(
      Map<String, dynamic>.from(await _client.get('inventory/stock', {'opticalStoreId': opticalStoreId}) as Map));

  Future<List<Supplier>> suppliers() async => _list(await _client.get('suppliers')).map(InventoryDto.supplier).toList();

  Future<List<StockMovement>> stockMovements({required String opticalStoreId, required DateTime from, required DateTime to, String? sku}) async =>
      _list(await _client.get('inventory/movements', {
        'opticalStoreId': opticalStoreId, 'from': from.toIso8601String().substring(0, 10),
        'to': to.toIso8601String().substring(0, 10), 'sku': sku,
      })).map(InventoryDto.movement).toList();

  Future<StockMovement> replenishStock({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock}) async =>
      InventoryDto.movement(Map<String, dynamic>.from(await _client.send('POST', 'inventory/replenishments', {
        'opticalStoreId': opticalStoreId, 'sku': sku, 'supplierId': supplierId, 'quantity': quantity,
        if (minimumStock != null) 'minimumStock': minimumStock,
      }) as Map));

  List<Map<String, dynamic>> _list(Object? json) => _client.mapList(json, 'El servidor devolvió una lista de inventario inválida.');
}
