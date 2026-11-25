import 'package:logix_optiflow/features/production/domain/staff_order.dart';

abstract final class StaffOrderDto {
  static StaffOrder fromJson(Map<String, dynamic> json) {
    final lenses = json['lenses'] as List? ?? [];
    return StaffOrder(
      id: json['id'] as String, patientId: json['patientId'] as String?, status: json['status'] as String,
      detail: lenses.isEmpty ? 'Sin lentes' : '${lenses.length} lentes · ${lenses.first['specifications'] ?? ''}',
      dueDate: json['estimatedDeliveryDate'] as String?, delayed: json['delayed'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
