class FrameItem {
  const FrameItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.fromPrice,
    required this.image,
    required this.description,
    required this.stock,
    required this.features,
    required this.colors,
    required this.size,
    this.sku = '',
    this.currency = 'PEN',
    this.stockKnown = false,
    this.minimumStock,
    this.tryOnModelUrl,
  });

  final String id;
  final String name;
  final String category;
  final num price;
  final String fromPrice;
  final String image;
  final String description;
  final int stock;
  final List<String> features;
  final List<String> colors;
  final int size;
  final String sku;
  final String currency;
  final bool stockKnown;
  final int? minimumStock;
  final String? tryOnModelUrl;
}
