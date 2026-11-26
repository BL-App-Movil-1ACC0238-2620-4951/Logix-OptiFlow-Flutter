import 'package:logix_optiflow/features/report/domain/report_repository.dart';
import 'package:logix_optiflow/features/report/domain/staff_alert.dart';
import 'package:logix_optiflow/features/report/infrastructure/report_local_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl();

  @override
  List<StaffAlert> alerts() => ReportLocalDataSource.alerts;
  @override
  List<double> reportBars() => ReportLocalDataSource.reportBars;
}
