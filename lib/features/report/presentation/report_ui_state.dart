import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/report/domain/report_metrics.dart';

class ReportUiState {
  const ReportUiState({
    required this.month,
    this.lowStock = const [],
    this.alertsLoading = false,
    this.alertsError,
    this.report,
    this.reportLoading = false,
    this.reportError,
    this.exporting,
    this.exportMessage,
    this.exportError,
  });

  final DateTime month;
  final List<LowStockAlert> lowStock;
  final bool alertsLoading;
  final String? alertsError;
  final MonthlyReport? report;
  final bool reportLoading;
  final String? reportError;
  final ReportKind? exporting;
  final String? exportMessage;
  final String? exportError;

  ReportUiState copyWith({
    DateTime? month,
    List<LowStockAlert>? lowStock,
    bool? alertsLoading,
    ValueGetter<String?>? alertsError,
    ValueGetter<MonthlyReport?>? report,
    bool? reportLoading,
    ValueGetter<String?>? reportError,
    ValueGetter<ReportKind?>? exporting,
    ValueGetter<String?>? exportMessage,
    ValueGetter<String?>? exportError,
  }) {
    return ReportUiState(
      month: month ?? this.month,
      lowStock: lowStock ?? this.lowStock,
      alertsLoading: alertsLoading ?? this.alertsLoading,
      alertsError: alertsError != null ? alertsError() : this.alertsError,
      report: report != null ? report() : this.report,
      reportLoading: reportLoading ?? this.reportLoading,
      reportError: reportError != null ? reportError() : this.reportError,
      exporting: exporting != null ? exporting() : this.exporting,
      exportMessage: exportMessage != null ? exportMessage() : this.exportMessage,
      exportError: exportError != null ? exportError() : this.exportError,
    );
  }
}
