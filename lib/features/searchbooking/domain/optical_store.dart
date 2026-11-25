class OpticalStore {
  const OpticalStore({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.status,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final double? rating;
  final String status;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;
}
