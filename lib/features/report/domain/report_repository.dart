import 'package:logix_optiflow/features/report/domain/report_metrics.dart';

abstract class ReportRepository {
  Future<SalesMetrics> sales(DateTime from, DateTime to);
  Future<ProductionMetrics> production(DateTime from, DateTime to);
  Future<InventoryMetrics> inventory(String opticalStoreId, DateTime from, DateTime to);
}
