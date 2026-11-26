/// Reportes que se exportan en CSV; `path` es el de `GET reports/{path}`.
enum ReportKind {
  sales('sales', 'Ventas'),
  production('production', 'Producción'),
  inventory('inventory', 'Inventario');

  const ReportKind(this.path, this.label);
  final String path;
  final String label;
}

/// Ventas cerradas y cotizaciones de un periodo (`GET /reports/sales`).
class SalesMetrics {
  const SalesMetrics({required this.attentions, required this.approvedQuotations, required this.rejectedQuotations, required this.closedSales, required this.totalAmount, required this.averageTicket});
  final int attentions;
  final int approvedQuotations;
  final int rejectedQuotations;
  final int closedSales;
  final double totalAmount;
  final double averageTicket;
}

/// Órdenes de trabajo de un periodo (`GET /reports/production`).
class ProductionMetrics {
  const ProductionMetrics({required this.ordersByStatus, required this.deliveredOrders, required this.averageFabricationHours, required this.delayedOrders});
  final Map<String, int> ordersByStatus;
  final int deliveredOrders;
  final double? averageFabricationHours;
  final int delayedOrders;
}

/// Entradas y salidas de stock de una óptica (`GET /reports/inventory`).
class InventoryMetrics {
  const InventoryMetrics({required this.unitsIn, required this.unitsOut, required this.lowStockProducts});
  final int unitsIn;
  final int unitsOut;
  final int lowStockProducts;
}

/// Métricas de un mes y lo vendido en los 6 meses que terminan en él.
class MonthlyReport {
  const MonthlyReport({required this.month, required this.sales, required this.production, required this.inventory, required this.salesHistory});
  final DateTime month;
  final SalesMetrics sales;
  final ProductionMetrics? production;
  final InventoryMetrics? inventory;

  /// Total vendido por mes, del más antiguo al pedido.
  final List<double> salesHistory;
}
