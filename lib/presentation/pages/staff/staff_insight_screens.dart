import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/report/presentation/report_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

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

  @override
  Widget build(BuildContext context) {
    final reportVm = getIt<ReportViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([reportVm, getIt<ProductionViewModel>()]),
      builder: (context, _) {
        final all = reportVm.alerts;
        final alerts = all.where((alert) {
          return switch (filter) {
            1 => alert.kind == 'Inventario',
            2 => alert.kind == 'Producción',
            _ => true,
          };
        }).toList();
        final error = reportVm.state.alertsError;
        return StaffScaffold(
          tab: StaffTab.more,
          topBar: StaffTopBar(title: 'Alertas', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _FilterChip(['Todas', 'Inventario', 'Producción'][i], filter == i, () => setState(() => filter = i)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(error, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400))),
                    TextButton(onPressed: reportVm.refreshAlerts, child: const Text('Reintentar')),
                  ]),
                ),
              if (reportVm.state.alertsLoading && all.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No hay alertas por ahora.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate400)),
                ),
              for (final alert in alerts) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconTile(
                            icon: alert.kind == 'Inventario' ? Icons.inventory_2_outlined : Icons.precision_manufacturing_outlined,
                            background: const Color(0xFFF1F5FF),
                            color: AppColors.staffAccent,
                            size: 34,
                            iconSize: 16,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert.title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                                const SizedBox(height: 8),
                                Text(alert.message, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => context.push(alert.route),
                          icon: Text(alert.action, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
                          label: const Icon(Icons.chevron_right, size: 16, color: AppColors.staffAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.staffBorder),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.staffAccent : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.staffAccent : AppColors.lavender),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: selected ? AppColors.white : AppColors.staffInk)),
      ),
    );
  }
}

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
        final history = report?.salesHistory ?? const <double>[];
        final top = history.fold<double>(0, (max, value) => value > max ? value : max);
        return StaffScaffold(
          tab: StaffTab.more,
          topBar: StaffTopBar(title: 'Reportes', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              AppCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: state.reportLoading ? null : () => reportVm.changeMonth(-1),
                      icon: const Icon(Icons.chevron_left, color: AppColors.staffInk),
                    ),
                    Expanded(
                      child: Text(
                        '${monthLabel[0].toUpperCase()}${monthLabel.substring(1)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk),
                      ),
                    ),
                    IconButton(
                      onPressed: state.reportLoading || isCurrent ? null : () => reportVm.changeMonth(1),
                      icon: const Icon(Icons.chevron_right, color: AppColors.staffInk),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (state.reportLoading && report == null)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (report == null)
                Column(children: [
                  Text(state.reportError ?? 'No hay datos para este mes.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate400)),
                  TextButton(onPressed: reportVm.refreshReport, child: const Text('Reintentar')),
                ])
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1E3D79), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ventas totales', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 14),
                      Text(soles(report.sales.totalAmount), style: GoogleFonts.inter(fontSize: 26, color: AppColors.white)),
                      const SizedBox(height: 10),
                      Text('Ventas de los últimos 6 meses', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 96,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < history.length; i++) ...[
                              Expanded(
                                child: FractionallySizedBox(
                                  heightFactor: top == 0 ? 0.04 : (history[i] / top).clamp(0.04, 1.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: i == history.length - 1 ? AppColors.white : AppColors.staffChip,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _ReportStat('${report.sales.attentions}', 'Atenciones', '${report.sales.approvedQuotations} cotizaciones aprobadas')),
                    const SizedBox(width: 14),
                    Expanded(child: _ReportStat('${report.sales.closedSales}', 'Ventas', '${soles(report.sales.averageTicket)} prom.')),
                  ],
                ),
                if (report.production != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _ReportStat('${report.production!.deliveredOrders}', 'Entregas', '${report.production!.delayedOrders} con retraso')),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ReportStat(
                          report.production!.averageFabricationHours == null ? '-' : report.production!.averageFabricationHours!.toStringAsFixed(1),
                          'Horas de fabricación',
                          'Promedio por orden',
                        ),
                      ),
                    ],
                  ),
                ],
                if (report.inventory != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _ReportStat('${report.inventory!.unitsIn}', 'Unidades ingresadas', '${report.inventory!.unitsOut} vendidas')),
                      const SizedBox(width: 14),
                      Expanded(child: _ReportStat('${report.inventory!.lowStockProducts}', 'Stock bajo', 'Monturas bajo el mínimo')),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(alignment: Alignment.centerRight, child: Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.staffInk))),
            const Spacer(),
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
          ],
        ),
      ),
    );
  }
}
