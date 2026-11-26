import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

abstract final class WorkOrderDetailDto {
  static WorkOrderDetail fromJson(Map<String, dynamic> json) {
    final lenses = json['lenses'];
    final history = json['statusHistory'];
    final delay = json['deliveryDelay'];
    return WorkOrderDetail(
      id: '${json['id']}',
      status: '${json['status'] ?? ''}',
      patientId: json['patientId']?.toString(),
      estimatedDeliveryDate: json['estimatedDeliveryDate']?.toString(),
      delayed: json['delayed'] == true,
      technician: namedRef(json['technician']),
      laboratory: namedRef(json['laboratory']),
      lenses: [
        if (lenses is List)
          for (final lens in lenses.whereType<Map>())
            Lens(id: lens['id']?.toString(), specifications: lens['specifications']?.toString(), completed: lens['completed'] == true),
      ],
      delayReason: delay is Map ? delay['reason']?.toString() : null,
      statusHistory: [
        if (history is List)
          for (final change in history.whereType<Map>())
            StatusChange('${change['status']}', DateTime.tryParse('${change['changedAt']}')),
      ],
    );
  }

  static NamedRef? namedRef(Object? json) => json is Map && json['id'] != null ? NamedRef('${json['id']}', '${json['name'] ?? ''}') : null;
}
