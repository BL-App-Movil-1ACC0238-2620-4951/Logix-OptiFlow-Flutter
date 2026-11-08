import '../../domain/entities/models.dart';

class OpticalStoreDto {
  const OpticalStoreDto({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.status,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final double? rating;
  final String status;

  factory OpticalStoreDto.fromJson(Map<String, dynamic> json) {
    return OpticalStoreDto(
      id: '${json['id']}',
      name: '${json['name'] ?? 'Óptica'}',
      address: '${json['address'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      rating: (json['rating'] as num?)?.toDouble(),
      status: '${json['status'] ?? ''}',
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
    );
  }
}

class StoreSearchDto {
  const StoreSearchDto({required this.stores, this.message});

  final List<OpticalStoreDto> stores;
  final String? message;
}
