import 'package:logix_optiflow/features/report/domain/report_metrics.dart';
import 'package:logix_optiflow/features/report/domain/report_repository.dart';

/// El reporte de un mes en CSV (`GET reports/{sales|production|inventory}` con `Accept: text/csv`).
class ExportReportUseCase {
  const ExportReportUseCase({required this.repository});

  final ReportRepository repository;

  Future<String> execute(ReportKind kind, DateTime month, String? opticalStoreId) =>
      repository.csv(kind, DateTime(month.year, month.month), DateTime(month.year, month.month + 1, 0), opticalStoreId);
}
