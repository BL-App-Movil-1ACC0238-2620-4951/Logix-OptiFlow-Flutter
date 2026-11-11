import '../../domain/entities/models.dart';

class WorkOrderDto {
  const WorkOrderDto({
    required this.id,
    required this.status,
    this.createdAt,
    this.estimatedDelivery,
    this.lensSpecification,
  });

  final String id;
  final String status;
  final DateTime? createdAt;
  final String? estimatedDelivery;
  final String? lensSpecification;

  factory WorkOrderDto.fromJson(Map<String, dynamic> json) {
    final lenses = json['lenses'];
    String? specification;
    if (lenses is List && lenses.isNotEmpty && lenses.first is Map) {
      final value = (lenses.first as Map)['specifications'];
      if (value != null) specification = '$value';
    }
    return WorkOrderDto(
      id: '${json['id']}',
      status: '${json['status'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      estimatedDelivery: json['estimatedDeliveryDate']?.toString(),
      lensSpecification: specification,
    );
  }

  WorkOrder toEntity() {
    return WorkOrder(
      id: id,
      status: status,
      createdAt: createdAt,
      estimatedDelivery: estimatedDelivery,
      lensSpecification: lensSpecification,
    );
  }
}
