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
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final String fromPrice;
  final String image;
  final String description;
  final int stock;
  final List<String> features;
  final List<String> colors;
  final int size;
}
