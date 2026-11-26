import 'package:logix_optiflow/features/report/domain/staff_alert.dart';

class ReportUiState {
  const ReportUiState({this.alerts = const [], this.reportBars = const []});

  final List<StaffAlert> alerts;
  final List<double> reportBars;

  ReportUiState copyWith({List<StaffAlert>? alerts, List<double>? reportBars}) {
    return ReportUiState(alerts: alerts ?? this.alerts, reportBars: reportBars ?? this.reportBars);
  }
}
