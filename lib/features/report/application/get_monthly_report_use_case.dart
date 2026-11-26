import 'package:logix_optiflow/features/report/domain/report_metrics.dart';
import 'package:logix_optiflow/features/report/domain/report_repository.dart';

/// Ventas, producción e inventario de un mes, y las ventas de los 6 meses que terminan en él.
class GetMonthlyReportUseCase {
  const GetMonthlyReportUseCase({required this.repository});

  final ReportRepository repository;

  Future<MonthlyReport> execute(DateTime month, String? opticalStoreId) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1, 0);
    Future<T?> optional<T>(Future<T> call) => call.then<T?>((value) => value, onError: (Object _) => null);
    final production = optional(repository.production(from, to));
    final inventory = opticalStoreId == null ? Future<InventoryMetrics?>.value() : optional(repository.inventory(opticalStoreId, from, to));
    final history = Future.wait([
      for (var back = 5; back >= 1; back--)
        optional(repository.sales(DateTime(month.year, month.month - back), DateTime(month.year, month.month - back + 1, 0))),
    ]);
    final sales = await repository.sales(from, to);
    return MonthlyReport(
      month: from, sales: sales, production: await production, inventory: await inventory,
      salesHistory: [...(await history).map((m) => m?.totalAmount ?? 0), sales.totalAmount],
    );
  }
}
