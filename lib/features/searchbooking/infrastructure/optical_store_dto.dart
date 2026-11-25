import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';

class OpticalStoreDto {
  const OpticalStoreDto({
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

  factory OpticalStoreDto.fromJson(Map<String, dynamic> json) {
    return OpticalStoreDto(
      id: '${json['id']}',
      name: '${json['name'] ?? 'Óptica'}',
      address: '${json['address'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      rating: (json['rating'] as num?)?.toDouble(),
      status: '${json['status'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  OpticalStore toEntity() {
    return OpticalStore(
      id: id,
      name: name,
      address: address,
      phone: phone,
      rating: rating,
      status: status,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class StoreSearchDto {
  const StoreSearchDto({required this.stores, this.message});

  final List<OpticalStoreDto> stores;
  final String? message;
}
