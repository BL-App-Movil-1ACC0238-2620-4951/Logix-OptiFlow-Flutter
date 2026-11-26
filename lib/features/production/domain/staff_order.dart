class StaffOrder {
  const StaffOrder({required this.id, required this.patientId, required this.status, required this.detail, required this.delayed, this.dueDate, this.createdAt});
  final String id;
  final String? patientId;
  final String status;
  final String detail;
  final bool delayed;
  final String? dueDate;
  final DateTime? createdAt;
  static const stages = ['PENDING', 'IN_WORKSHOP', 'QUALITY_CONTROL', 'READY_FOR_DELIVERY', 'DELIVERED'];
  int get step => !stages.contains(status) ? 0 : stages.indexOf(status);
  String get label => switch (status) {
    'PENDING' => 'Pendiente', 'IN_WORKSHOP' => 'En taller', 'QUALITY_CONTROL' => 'Control de calidad',
    'READY_FOR_DELIVERY' => 'Lista para entrega', 'DELIVERED' => 'Entregada', _ => status,
  };
}
