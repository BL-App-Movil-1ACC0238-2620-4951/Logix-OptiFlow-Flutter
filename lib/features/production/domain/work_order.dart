class WorkOrder {
  const WorkOrder({
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
  /// Motivo del retraso; solo existe si el taller marcó la orden como atrasada.
  final String? delayReason;
  final List<WorkOrderStatusChange> statusHistory;
}

/// Momento en que la orden llegó a un estado (PENDING, IN_WORKSHOP, …).
class WorkOrderStatusChange {
  const WorkOrderStatusChange(this.status, this.changedAt);
  final String status;
  final DateTime changedAt;
}
