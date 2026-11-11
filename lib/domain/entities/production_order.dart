enum ProductionStage {
  pending('Por iniciar'),
  inWorkshop('En producción'),
  qualityControl('Control calidad'),
  ready('Listos'),
  delivered('Entregados');

  const ProductionStage(this.label);
  final String label;
}

class ProductionOrder {
  const ProductionOrder({
    required this.code,
    required this.patient,
    required this.detail,
    required this.stage,
    required this.due,
    this.needsAttention = false,
  });

  final String code;
  final String patient;
  final String detail;
  final ProductionStage stage;
  final String due;
  final bool needsAttention;
}
