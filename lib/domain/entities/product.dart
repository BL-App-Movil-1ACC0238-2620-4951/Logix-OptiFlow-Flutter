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
}
