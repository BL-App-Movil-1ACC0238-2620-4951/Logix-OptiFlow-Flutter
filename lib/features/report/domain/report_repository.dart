import 'package:logix_optiflow/features/report/domain/staff_alert.dart';

abstract class ReportRepository {
  List<StaffAlert> alerts();
  List<double> reportBars();
}
