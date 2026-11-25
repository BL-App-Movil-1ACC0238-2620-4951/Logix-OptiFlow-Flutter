class WorkOrder {
  const WorkOrder({
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
}
