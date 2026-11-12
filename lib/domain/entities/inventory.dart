class StockLevel {
  const StockLevel({required this.sku, required this.quantity, required this.minimumStock});
  final String sku;
  final int quantity;
  final int minimumStock;
  bool get low => quantity <= minimumStock;
}

class StoreInventory {
  const StoreInventory({required this.opticalStoreId, required this.stocks});
  final String opticalStoreId;
  final List<StockLevel> stocks;
}

class Supplier {
  const Supplier({required this.id, required this.name, required this.contact});
  final String id;
  final String name;
  final String contact;
}

class StockMovement {
  const StockMovement({required this.id, required this.sku, required this.name, required this.type, required this.reason, required this.quantity, required this.createdAt});
  final String id;
  final String sku;
  final String name;
  final String type;
  final String reason;
  final int quantity;
  final DateTime createdAt;
}
