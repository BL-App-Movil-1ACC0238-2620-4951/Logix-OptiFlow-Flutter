import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/report/domain/report_metrics.dart';

/// Métricas del administrador (`/reports/sales`, `/reports/production`, `/reports/inventory`).
class ReportApi {
  const ReportApi(this._client);

  final ApiClient _client;

  Future<SalesMetrics> sales(DateTime from, DateTime to) async {
    final json = await _map('reports/sales', from, to);
    return SalesMetrics(
      attentions: _int(json['attentions']), approvedQuotations: _int(json['approvedQuotations']),
      rejectedQuotations: _int(json['rejectedQuotations']), closedSales: _int(json['closedSales']),
      totalAmount: _double(json['totalAmount']) ?? 0, averageTicket: _double(json['averageTicket']) ?? 0,
    );
  }

  Future<ProductionMetrics> production(DateTime from, DateTime to) async {
    final json = await _map('reports/production', from, to);
    final byStatus = json['ordersByStatus'] is Map ? Map<String, dynamic>.from(json['ordersByStatus'] as Map) : const <String, dynamic>{};
    return ProductionMetrics(
      ordersByStatus: {for (final entry in byStatus.entries) entry.key: _int(entry.value)},
      deliveredOrders: _int(json['deliveredOrders']), averageFabricationHours: _double(json['averageFabricationHours']),
      delayedOrders: _int(json['delayedOrders']),
    );
  }

  Future<InventoryMetrics> inventory(String opticalStoreId, DateTime from, DateTime to) async {
    final json = await _map('reports/inventory', from, to, {'opticalStoreId': opticalStoreId});
    return InventoryMetrics(unitsIn: _int(json['unitsIn']), unitsOut: _int(json['unitsOut']), lowStockProducts: _int(json['lowStockProducts']));
  }

  Future<Map<String, dynamic>> _map(String path, DateTime from, DateTime to, [Map<String, String?> extra = const {}]) async {
    final json = await _client.get(path, {'from': _day(from), 'to': _day(to), ...extra});
    if (json is! Map) throw ApiException('El servidor devolvió un reporte inválido.');
    return Map<String, dynamic>.from(json);
  }

  static String _day(DateTime date) => date.toIso8601String().substring(0, 10);
  static int _int(Object? value) => value is num ? value.toInt() : 0;
  static double? _double(Object? value) => value is num ? value.toDouble() : null;
}
