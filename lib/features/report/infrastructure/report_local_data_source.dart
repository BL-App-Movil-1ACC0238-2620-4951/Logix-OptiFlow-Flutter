import 'package:logix_optiflow/features/report/domain/staff_alert.dart';

/// Alertas y barras de muestra del administrador (se reemplazan por la API en la rama de datos demo).
class ReportLocalDataSource {
  static const alerts = <StaffAlert>[
    StaffAlert(kind: 'Inventario', title: 'Stock bajo', message: 'Milo M-8 tiene solo 3 unidades.', action: 'Revisar stock'),
    StaffAlert(kind: 'Producción', title: 'Orden con retraso', message: 'OT-2039 lleva 1 día de retraso.', action: 'Ver orden'),
    StaffAlert(kind: 'Producción', title: 'Pedidos listos', message: '3 pedidos esperan ser entregados.', action: 'Ver pedidos'),
  ];

  static const reportBars = [0.45, 0.65, 0.53, 0.80, 0.72, 1.0, 0.87];
}
