/// Orden de trabajo completa del taller (`GET work-orders/{id}`).
class WorkOrderDetail {
  const WorkOrderDetail({
    required this.id,
    required this.status,
    this.patientId,
    this.estimatedDeliveryDate,
    this.delayed = false,
    this.technician,
    this.laboratory,
    this.lenses = const [],
    this.delayReason,
    this.statusHistory = const [],
  });

  final String id;
  final String status;
  final String? patientId;
  /// Fecha ISO (aaaa-mm-dd).
  final String? estimatedDeliveryDate;
  final bool delayed;
  final NamedRef? technician;
  final NamedRef? laboratory;
  final List<Lens> lenses;
  final String? delayReason;
  final List<StatusChange> statusHistory;

  String get code => 'OT-${id.substring(0, id.length < 4 ? id.length : 4).toUpperCase()}';
}

/// Técnico o laboratorio.
class NamedRef {
  const NamedRef(this.id, this.name);
  final String id;
  final String name;
}

class Lens {
  const Lens({this.id, this.specifications, this.completed = false});
  final String? id;
  final String? specifications;
  final bool completed;
}

class StatusChange {
  const StatusChange(this.status, this.changedAt);
  final String status;
  final DateTime? changedAt;
}

/// Estados de la orden en el backend, en el orden del tablero del taller.
abstract final class WorkOrderStatus {
  static const pending = 'PENDING';
  static const inWorkshop = 'IN_WORKSHOP';
  static const qualityControl = 'QUALITY_CONTROL';
  static const readyForDelivery = 'READY_FOR_DELIVERY';
  static const delivered = 'DELIVERED';

  static const order = [pending, inWorkshop, qualityControl, readyForDelivery, delivered];

  /// Siguiente etapa; null si ya fue entregada.
  static String? next(String status) {
    final index = order.indexOf(status);
    return index < 0 || index + 1 >= order.length ? null : order[index + 1];
  }

  static String label(String status) => switch (status) {
        pending => 'Pendiente',
        inWorkshop => 'En taller',
        qualityControl => 'Control de calidad',
        readyForDelivery => 'Lista para entrega',
        delivered => 'Entregada',
        _ => status,
      };
}

/// Técnicos y laboratorios para asignar la orden.
class WorkshopCatalog {
  const WorkshopCatalog({this.technicians = const [], this.laboratories = const []});
  final List<NamedRef> technicians;
  final List<NamedRef> laboratories;
}
