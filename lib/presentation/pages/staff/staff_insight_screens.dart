import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart' show soles;
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/report/domain/report_metrics.dart';
import 'package:logix_optiflow/features/report/presentation/report_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

const _soft = Color(0xFFF1F5FF);
const _reportBlue = Color(0xFF1E3D79);
const _slate500 = Color(0xFF64748B);

void _back(BuildContext context) => context.canPop() ? context.pop() : context.go('/s/more');

Widget _muted(String text) => Text(text, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400));

/// Stock crítico y órdenes que requieren atención (`/s/alerts`), igual a Kotlin.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<ReportViewModel>().refreshAlerts(); });
  }

  /// Se relee al volver de reponer stock o de una orden.
  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) getIt<ReportViewModel>().refreshAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final reportVm = getIt<ReportViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([reportVm, getIt<ProductionViewModel>()]),
      builder: (context, _) {
        final all = reportVm.alerts;
        final alerts = all.where((alert) => switch (filter) {
              1 => alert.kind == 'Inventario',
              2 => alert.kind == 'Producción',
              _ => true,
            }).toList();
        final error = reportVm.state.alertsError;
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Alertas', onBack: () => _back(context)),
          body: RefreshIndicator(
            onRefresh: reportVm.refreshAlerts,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Row(children: [
                  for (final (i, label) in const ['Todas', 'Inventario', 'Producción'].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    StaffChip(label, selected: filter == i, onTap: () => setState(() => filter = i)),
                  ],
                ]),
                const SizedBox(height: 20),
                StaffSectionTitle('Pendientes · ${alerts.length}'),
                const SizedBox(height: 12),
                if (reportVm.state.alertsLoading && all.isEmpty)
                  _muted('Cargando...')
                else ...[
                  if (error != null)
                    Row(children: [
                      Expanded(child: _muted(error)),
                      TextButton(onPressed: reportVm.refreshAlerts, child: const Text('Reintentar')),
                    ]),
                  if (alerts.isEmpty && error == null) _muted('Sin alertas por ahora.'),
                ],
                for (final alert in alerts) ...[
                  AppCard(
                    radius: 18,
                    borderColor: AppColors.staffBorder,
                    padding: const EdgeInsets.all(14),
                    onTap: () => _open(alert.route),
                    child: Row(children: [
                      StaffIconTile(
                        alert.kind == 'Inventario'
                            ? LucideIcons.bell
                            : alert.title == 'Pedidos listos'
                                ? LucideIcons.box
                                : LucideIcons.clock,
                        size: 40,
                        background: _soft,
                        radius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(alert.title, style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                          const SizedBox(height: 2),
                          Text(alert.message, style: AppFonts.inter(fontSize: 11, color: _slate500)),
                          const SizedBox(height: 6),
                          Text(alert.action, style: AppFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.staffInk),
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ventas, producción e inventario del mes y exportación en CSV (`/s/reports`), igual a Kotlin.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<ReportViewModel>().refreshReport(); });
  }

  /// Pide el CSV y abre "Guardar como" para que el usuario elija dónde dejarlo.
  Future<void> _export(ReportKind kind) async {
    final reportVm = getIt<ReportViewModel>();
    final month = reportVm.state.month;
    final csv = await reportVm.export(kind);
    if (csv == null || !mounted) return;
    bool? ok;
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'optiflow-${kind.path}-${DateFormat('yyyy-MM').format(month)}.csv',
        bytes: utf8.encode(csv),
        mimeType: 'text/csv',
        dialogTitle: 'Guardar reporte',
      );
      ok = uri == null ? null : true;
    } catch (_) {
      ok = false;
    }
    reportVm.saved(ok);
  }

  @override
  Widget build(BuildContext context) {
    final reportVm = getIt<ReportViewModel>();
    return ListenableBuilder(
      listenable: reportVm,
      builder: (context, _) {
        final state = reportVm.state;
        final report = state.report;
        final monthLabel = DateFormat('MMMM y', 'es').format(state.month);
        final now = StoreTime.today();
        final isCurrent = state.month.year == now.year && state.month.month == now.month;
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Reportes', onBack: () => _back(context)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.lavender)),
                child: Row(children: [
                  _MonthArrow(LucideIcons.chevronLeft, state.reportLoading ? null : () => reportVm.changeMonth(-1)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${monthLabel[0].toUpperCase()}${monthLabel.substring(1)}', style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                    ),
                  ),
                  _MonthArrow(LucideIcons.chevronRight, state.reportLoading || isCurrent ? null : () => reportVm.changeMonth(1)),
                ]),
              ),
              const SizedBox(height: 14),
              if (report == null) ...[
                _muted(state.reportLoading ? 'Cargando...' : state.reportError ?? 'No hay datos para este mes.'),
                if (!state.reportLoading) Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: reportVm.refreshReport, child: const Text('Reintentar'))),
              ] else ...[
                _SalesHero(report),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _ReportStat('${report.sales.approvedQuotations}', 'Cotizaciones aprobadas', '${report.sales.rejectedQuotations} rechazadas')),
                  const SizedBox(width: 14),
                  Expanded(child: _ReportStat(
                    '${report.production?.ordersByStatus.values.fold<int>(0, (a, b) => a + b) ?? 0}',
                    'Órdenes de trabajo',
                    report.production == null
                        ? '—'
                        : '${report.production!.delayedOrders} atrasadas'
                            '${report.production!.averageFabricationHours == null ? '' : ' · ${report.production!.averageFabricationHours!.toStringAsFixed(1)} h prom.'}',
                  )),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _ReportStat('${report.inventory?.unitsOut ?? 0}', 'Unidades vendidas', '${report.inventory?.unitsIn ?? 0} ingresaron')),
                  const SizedBox(width: 14),
                  Expanded(child: _ReportStat('${report.inventory?.lowStockProducts ?? 0}', 'Stock crítico', 'monturas bajo el mínimo')),
                ]),
                const SizedBox(height: 22),
                const StaffSectionTitle('Exportar en CSV'),
                const SizedBox(height: 12),
                if (state.exportMessage != null) ...[
                  Text(state.exportMessage!, style: AppFonts.inter(fontSize: 12, color: AppColors.staffGreen)),
                  const SizedBox(height: 10),
                ],
                if (state.exportError != null) ...[
                  Text(state.exportError!, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
                  const SizedBox(height: 10),
                ],
                for (final kind in ReportKind.values) ...[
                  StaffButton(
                    label: state.exporting == kind ? 'Preparando...' : 'Exportar ${kind.label}',
                    icon: LucideIcons.fileText,
                    background: AppColors.white,
                    foreground: AppColors.staffInk,
                    border: AppColors.staffBorder,
                    onPressed: state.exporting != null ? null : () => _export(kind),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Icon(icon, size: 22, color: onTap == null ? AppColors.slate300 : AppColors.staffInk),
      );
}

class _SalesHero extends StatelessWidget {
  const _SalesHero(this.report);
  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final history = report.salesHistory;
    final top = history.fold<double>(0, (max, value) => value > max ? value : max);
    final soft = AppFonts.inter(fontSize: 9, color: AppColors.white.withValues(alpha: 0.8));
    final months = [for (var back = history.length - 1; back >= 0; back--) DateTime(report.month.year, report.month.month - back)];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _reportBlue, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ventas cobradas', style: soft),
        const SizedBox(height: 14),
        Text(soles(report.sales.totalAmount), style: AppFonts.inter(fontSize: 26, color: AppColors.white)),
        const SizedBox(height: 10),
        Text('Ticket promedio ${soles(report.sales.averageTicket)}', style: soft),
        const SizedBox(height: 16),
        SizedBox(
          height: 96,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < history.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: top == 0 ? 0.03 : (history[i] / top).clamp(0.03, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i == history.length - 1 ? AppColors.white : AppColors.staffChip,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 6),
        Row(children: [
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: Text(DateFormat('MMM', 'es').format(months[i]).replaceAll('.', ''), style: AppFonts.inter(fontSize: 8, color: AppColors.white.withValues(alpha: 0.8)))),
          ],
        ]),
      ]),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat(this.value, this.title, this.subtitle);
  final String value;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      borderColor: AppColors.lavender,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 88,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(alignment: Alignment.centerRight, child: Text(value, style: AppFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.staffInk))),
          const Spacer(),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
        ]),
      ),
    );
  }
}
