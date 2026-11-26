import 'package:logix_optiflow/features/production/domain/work_order.dart';

class WorkOrderDto {
  const WorkOrderDto({
    required this.id,
    required this.status,
    this.createdAt,
    this.estimatedDelivery,
    this.lensSpecification,
    this.saleId,
    this.opticalStoreId,
    this.delayReason,
    this.statusHistory = const [],
  });

  final String id;
  final String status;
  final DateTime? createdAt;
  final String? estimatedDelivery;
  final String? lensSpecification;
  final String? saleId;
  final String? opticalStoreId;
  final String? delayReason;
  final List<WorkOrderStatusChange> statusHistory;

  factory WorkOrderDto.fromJson(Map<String, dynamic> json) {
    final lenses = json['lenses'];
    String? specification;
    if (lenses is List && lenses.isNotEmpty && lenses.first is Map) {
      final value = (lenses.first as Map)['specifications'];
      if (value != null) specification = '$value';
    }
    final delay = json['deliveryDelay'];
    final history = json['statusHistory'];
    return WorkOrderDto(
      id: '${json['id']}',
      status: '${json['status'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      estimatedDelivery: json['estimatedDeliveryDate']?.toString(),
      lensSpecification: specification,
      saleId: json['saleId']?.toString(),
      opticalStoreId: json['opticalStoreId']?.toString(),
      delayReason: json['delayed'] == true && delay is Map ? delay['reason']?.toString() : null,
      statusHistory: [
        if (history is List)
          for (final change in history.whereType<Map>())
            if (DateTime.tryParse('${change['changedAt']}') case final at?) WorkOrderStatusChange('${change['status']}', at.toLocal()),
      ],
    );
  }

  WorkOrder toEntity() {
    return WorkOrder(
      id: id,
      status: status,
      createdAt: createdAt,
      estimatedDelivery: estimatedDelivery,
      lensSpecification: lensSpecification,
      saleId: saleId,
      opticalStoreId: opticalStoreId,
      delayReason: delayReason,
      statusHistory: statusHistory,
    );
  }
}
