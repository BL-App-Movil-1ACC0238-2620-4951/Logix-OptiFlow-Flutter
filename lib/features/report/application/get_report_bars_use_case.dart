import 'package:logix_optiflow/features/report/domain/report_repository.dart';

class GetReportBarsUseCase {
  const GetReportBarsUseCase({required this.repository});

  final ReportRepository repository;

  List<double> execute() => repository.reportBars();
}
