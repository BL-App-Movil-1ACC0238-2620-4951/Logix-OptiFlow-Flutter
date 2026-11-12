class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.code,
    required this.detail,
    required this.price,
    required this.tag,
    required this.available,
    required this.image,
    required this.category,
    required this.size,
    required this.location,
    required this.supplier,
    this.quantityKnown = true,
    this.minimumStock,
  });

  final String id;
  final String name;
  final String sku;
  final String code;
  final String detail;
  final String price;
  final String tag;
  final int available;
  final String image;
  final String category;
  final String size;
  final String location;
  final String supplier;
  final bool quantityKnown;
  final int? minimumStock;

  ProductItem withPrice(String value) => ProductItem(
    id: id, name: name, sku: sku, code: code, detail: detail,
    price: value, tag: tag, available: available, image: image,
    category: category, size: size, location: location, supplier: supplier,
    quantityKnown: quantityKnown, minimumStock: minimumStock,
  );
}
