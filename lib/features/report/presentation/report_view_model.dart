import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/report/application/get_report_bars_use_case.dart';
import 'package:logix_optiflow/features/report/application/get_staff_alerts_use_case.dart';
import 'package:logix_optiflow/features/report/presentation/report_ui_state.dart';

/// Alertas y reportes del administrador (hoy con datos de muestra).
class ReportViewModel extends ChangeNotifier {
  ReportViewModel({required this.getStaffAlertsUseCase, required this.getReportBarsUseCase}) {
    _state = ReportUiState(alerts: getStaffAlertsUseCase.execute(), reportBars: getReportBarsUseCase.execute());
  }

  final GetStaffAlertsUseCase getStaffAlertsUseCase;
  final GetReportBarsUseCase getReportBarsUseCase;

  late ReportUiState _state;
  ReportUiState get state => _state;
}
