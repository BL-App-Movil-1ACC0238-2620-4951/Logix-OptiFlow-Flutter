import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final alerts = context.read<OptiFlowController>().alerts.where((alert) {
      return switch (filter) {
        1 => alert.kind == 'Inventario',
        2 => alert.kind == 'Producción',
        _ => true,
      };
    }).toList();
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
                      onPressed: () {
                        if (alert.kind == 'Inventario') {
                          context.push('/s/stock/rb5154');
                        } else {
                          context.push('/s/production');
                        }
                      },
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

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bars = context.read<OptiFlowController>().reportBars;
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Reportes', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AppCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text('Este mes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                const SizedBox(width: 10),
                Expanded(child: Text('Junio 2025', style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk))),
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.staffInk),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E3D79), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ventas totales', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 14),
                Text('\$8.460.200', style: GoogleFonts.inter(fontSize: 26, color: AppColors.white)),
                const SizedBox(height: 10),
                Text('18% sobre el mes anterior', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 16),
                SizedBox(
                  height: 96,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final bar in bars) ...[
                        Expanded(
                          child: FractionallySizedBox(
                            heightFactor: bar,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: bar == 1 ? AppColors.white : AppColors.staffChip,
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
          const Row(
            children: [
              Expanded(child: _ReportStat('126', 'Atenciones', '92% asistió')),
              SizedBox(width: 14),
              Expanded(child: _ReportStat('84', 'Ventas', '\$100.716 prom.')),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            onTap: () => showAppMessage(context, 'Reporte exportado'),
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 18, color: AppColors.staffInk),
                const SizedBox(width: 10),
                Text('Exportar reporte', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.staffInk)),
              ],
            ),
          ),
        ],
      ),
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
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
          ],
        ),
      ),
    );
  }
}
