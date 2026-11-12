import '../../domain/entities/frame.dart';
import '../../domain/entities/inventory.dart';

class FrameModelDto {
  const FrameModelDto(this.json);
  final Map<String, dynamic> json;

  FrameItem toEntity() {
    final sku = json['sku'] as String;
    final price = json['price'] as num;
    final currency = json['currency'] as String? ?? 'PEN';
    final material = json['material'] as String? ?? '';
    final shape = json['shape'] as String? ?? '';
    final color = json['color'] as String? ?? '';
    return FrameItem(
      id: sku, sku: sku, name: json['name'] as String,
      category: 'Monturas', price: price, currency: currency,
      fromPrice: '${currency == 'PEN' ? 'S/' : currency} ${price.toStringAsFixed(2)}',
      image: '', description: [material, shape, color].where((s) => s.isNotEmpty).join(' · '),
      stock: (json['quantity'] as num?)?.toInt() ?? 0,
      stockKnown: json['quantity'] != null,
      minimumStock: (json['minimumStock'] as num?)?.toInt(),
      features: [material, shape].where((s) => s.isNotEmpty).toList(),
      colors: color.isEmpty ? [] : [color], size: 0,
      tryOnModelUrl: json['tryOnModelUrl'] as String?,
    );
  }
}

abstract final class InventoryDto {
  static StoreInventory stock(Map<String, dynamic> json) => StoreInventory(
    opticalStoreId: json['opticalStoreId'] as String,
    stocks: (json['stocks'] as List).map((item) => StockLevel(
      sku: item['sku'] as String, quantity: (item['quantity'] as num).toInt(),
      minimumStock: (item['minimumStock'] as num).toInt(),
    )).toList(),
  );

  static Supplier supplier(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String, name: json['name'] as String, contact: json['contact'] as String? ?? '',
  );

  static StockMovement movement(Map<String, dynamic> json) => StockMovement(
    id: json['id'] as String, sku: json['sku'] as String,
    name: json['frameModelName'] as String? ?? json['sku'] as String,
    type: json['type'] as String, reason: json['reason'] as String,
    quantity: (json['quantity'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );
}
