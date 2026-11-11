import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/production_order.dart';
import '../../domain/entities/staff_alert.dart';
import '../../domain/entities/staff_patient.dart';

class StaffLocalDataSource {
  static const patients = <StaffPatient>[
    StaffPatient(id: 'vs', initials: 'VS', name: 'Valentina Silva', fullName: 'Valentina Silva Morales', rut: '18.234.567-8', note: 'Control hoy · 10:30', phone: '+56 9 8412 9043', lastVisit: '24 jun 2024', ficha: 'OPT-2024-849', age: 28),
    StaffPatient(id: 'mg', initials: 'MG', name: 'María González', fullName: 'María González Pérez', rut: '12.345.678-9', note: 'Último control · 12 jun', phone: '+56 9 7781 2201', lastVisit: '12 jun 2024', ficha: 'OPT-2024-612', age: 41),
    StaffPatient(id: 'tf', initials: 'TF', name: 'Tomás Fuentes', fullName: 'Tomás Fuentes Ríos', rut: '20.481.292-1', note: 'Nuevo paciente', phone: '+56 9 6620 4419', lastVisit: '—', ficha: 'OPT-2024-901', age: 23),
    StaffPatient(id: 'cr', initials: 'CR', name: 'Camila Rojas', fullName: 'Camila Rojas Díaz', rut: '16.902.456-4', note: 'Último control · 03 may', phone: '+56 9 5310 7782', lastVisit: '03 may 2024', ficha: 'OPT-2024-433', age: 35),
    StaffPatient(id: 'cm', initials: 'CM', name: 'Carlos Mendoza', fullName: 'Carlos Mendoza Vera', rut: '15.118.903-2', note: 'Control post-graduación', phone: '+56 9 4471 0098', lastVisit: '18 jun 2024', ficha: 'OPT-2024-702', age: 52),
    StaffPatient(id: 'mr', initials: 'MR', name: 'Mariana Rojas', fullName: 'Mariana Rojas Soto', rut: '19.554.120-7', note: 'Por confirmar', phone: '+56 9 9012 3345', lastVisit: '—', ficha: 'OPT-2024-911', age: 30),
  ];

  static const agenda = <AgendaItem>[
    AgendaItem(time: '10:30', duration: '45 min', patientId: 'vs', name: 'Valentina Silva', service: 'Evaluación visual completa', status: AgendaStatus.waiting),
    AgendaItem(time: '11:15', duration: '45 min', patientId: 'cm', name: 'Carlos Mendoza', service: 'Control post-graduación', status: AgendaStatus.confirmed),
    AgendaItem(time: '12:00', duration: '45 min', patientId: 'mr', name: 'Mariana Rojas', service: 'Primera consulta', status: AgendaStatus.pending),
    AgendaItem(time: '13:00', duration: '30 min', patientId: 'mg', name: 'María González', service: 'Retiro de lentes', status: AgendaStatus.pickup),
    AgendaItem(time: '15:00', duration: '45 min', patientId: 'cr', name: 'Camila Rojas', service: 'Control anual', status: AgendaStatus.confirmed),
    AgendaItem(time: '16:00', duration: '30 min', patientId: 'tf', name: 'Tomás Fuentes', service: 'Retiro de lentes', status: AgendaStatus.pickup),
    AgendaItem(time: '16:30', duration: '45 min', patientId: 'mg', name: 'María González', service: 'Adaptación de lentes', status: AgendaStatus.confirmed),
    AgendaItem(time: '17:15', duration: '45 min', patientId: 'cm', name: 'Carlos Mendoza', service: 'Cambio de cristales', status: AgendaStatus.confirmed),
  ];

  static const products = <ProductItem>[
    ProductItem(id: 'rb5154', name: 'Ray-Ban Clubmaster', sku: 'RB5154', code: 'RB-5154-51-21', detail: 'Carey / Dorado · Acetato', price: '\$189.000', tag: 'Alta demanda', available: 4, image: 'assets/images/img_inv_clubmaster.png', category: 'Armazones', size: '51-21-145', location: 'Vitrina Centro', supplier: 'EssilorLuxottica'),
    ProductItem(id: 'holbrook', name: 'Holbrook RX', sku: 'OX8156', code: 'OX-8156-54-18', detail: 'Negro mate · O-Matter', price: '\$165.000', tag: 'Deportivo', available: 2, image: 'assets/images/img_inv_holbrook.png', category: 'Armazones', size: '54-18-137', location: 'Vitrina Centro', supplier: 'Oakley'),
    ProductItem(id: 'titan', name: 'Titan Minimal', sku: 'TM1520', code: 'TM-1520-52-17', detail: 'Sin montura · Titanio', price: '\$290.000', tag: 'Titanio', available: 6, image: 'assets/images/img_inv_titan.png', category: 'Armazones', size: '52-17-140', location: 'Vitrina Norte', supplier: 'Silhouette'),
    ProductItem(id: 'vo5282', name: 'VO5282B Cat-Eye', sku: 'VO5282B', code: 'VO-5282-53-17', detail: 'Borgoña · Acetato fino', price: '\$138.000', tag: 'Última unidad', available: 1, image: 'assets/images/img_inv_vogue.png', category: 'Armazones', size: '53-17-140', location: 'Cajón Taller', supplier: 'Vogue Eyewear'),
  ];

  ProductItem product(String id) => products.firstWhere((item) => item.id == id, orElse: () => products.first);

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

  static const alerts = <StaffAlert>[
    StaffAlert(kind: 'Inventario', title: 'Stock bajo', message: 'Milo M-8 tiene solo 3 unidades.', action: 'Revisar stock'),
    StaffAlert(kind: 'Producción', title: 'Orden con retraso', message: 'OT-2039 lleva 1 día de retraso.', action: 'Ver orden'),
    StaffAlert(kind: 'Producción', title: 'Pedidos listos', message: '3 pedidos esperan ser entregados.', action: 'Ver pedidos'),
  ];

  static const reportBars = [0.45, 0.65, 0.53, 0.80, 0.72, 1.0, 0.87];
}
