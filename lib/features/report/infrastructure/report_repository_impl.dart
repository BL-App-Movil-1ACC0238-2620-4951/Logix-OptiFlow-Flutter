import 'package:logix_optiflow/features/report/domain/report_metrics.dart';
import 'package:logix_optiflow/features/report/domain/report_repository.dart';
import 'package:logix_optiflow/features/report/infrastructure/report_api.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl({required this.api});

  final ReportApi api;

  @override
  Future<SalesMetrics> sales(DateTime from, DateTime to) => api.sales(from, to);
  @override
  Future<ProductionMetrics> production(DateTime from, DateTime to) => api.production(from, to);
  @override
  Future<InventoryMetrics> inventory(String opticalStoreId, DateTime from, DateTime to) => api.inventory(opticalStoreId, from, to);
}
