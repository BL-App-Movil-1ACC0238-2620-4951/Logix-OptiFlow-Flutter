import 'package:logix_optiflow/features/production/domain/production_order.dart';

/// Datos de muestra del tablero de producción (se reemplazan por la API en la rama de datos demo).
class ProductionLocalDataSource {
  static const productionOrders = <ProductionOrder>[
    ProductionOrder(code: 'OT-2048', patient: 'Valentina Silva', detail: 'Nova N-24 · Monofocal 1.60', stage: ProductionStage.inWorkshop, due: 'Entrega 28 jun'),
    ProductionOrder(code: 'OT-2042', patient: 'María González', detail: 'Aira 302 · Monofocal 1.60', stage: ProductionStage.inWorkshop, due: 'Entrega hoy'),
    ProductionOrder(code: 'OT-2039', patient: 'Tomás Fuentes', detail: 'Milo M-8 · Monofocal 1.60', stage: ProductionStage.inWorkshop, due: 'Atrasada 1 día', needsAttention: true),
    ProductionOrder(code: 'OT-2051', patient: 'Camila Rojas', detail: 'Verona · Bifocal 1.56', stage: ProductionStage.pending, due: 'Entrega 2 jul'),
    ProductionOrder(code: 'OT-2052', patient: 'Carlos Mendoza', detail: 'Roma · Progresivo 1.67', stage: ProductionStage.pending, due: 'Entrega 3 jul'),
    ProductionOrder(code: 'OT-2053', patient: 'Mariana Rojas', detail: 'Amber · Monofocal 1.50', stage: ProductionStage.pending, due: 'Entrega 3 jul'),
    ProductionOrder(code: 'OT-2031', patient: 'Ana Torres', detail: 'Holbrook · Monofocal 1.60', stage: ProductionStage.qualityControl, due: 'Entrega mañana'),
    ProductionOrder(code: 'OT-2029', patient: 'Luis Paredes', detail: 'Titan · Progresivo 1.67', stage: ProductionStage.qualityControl, due: 'Entrega mañana'),
    ProductionOrder(code: 'OT-2020', patient: 'Pedro Ruiz', detail: 'Clubmaster · Monofocal', stage: ProductionStage.ready, due: 'Listo para retiro'),
  ];
}
