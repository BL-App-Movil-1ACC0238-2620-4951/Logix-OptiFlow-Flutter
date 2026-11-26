import 'package:logix_optiflow/features/report/domain/report_repository.dart';
import 'package:logix_optiflow/features/report/domain/staff_alert.dart';

class GetStaffAlertsUseCase {
  const GetStaffAlertsUseCase({required this.repository});

  final ReportRepository repository;

  List<StaffAlert> execute() => repository.alerts();
}
