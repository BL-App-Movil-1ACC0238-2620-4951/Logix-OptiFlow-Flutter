import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/searchbooking/domain/agenda_item.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/report/presentation/report_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/pages/patient/search_screen.dart' show SearchField;
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';
import 'package:logix_optiflow/presentation/widgets/frame_photos.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';

export 'package:logix_optiflow/presentation/pages/staff/staff_admin_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_care_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_evaluation_screen.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_insight_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_inventory_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_record_screen.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_sale_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_scanner_screen.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_work_order_screen.dart';

String _greeting() {
  final hour = StoreTime.clock(DateTime.now()).hour;
  if (hour >= 5 && hour <= 11) return 'Buenos días';
  if (hour >= 12 && hour <= 18) return 'Buenas tardes';
  return 'Buenas noches';
}

String _initialsOf(String name) => name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0].toUpperCase()).join();

String _agendaDateLabel(DateTime date) => DateFormat("EEEE d 'de' MMMM", 'es').format(date).toUpperCase();

/// Tarjeta blanca del personal con el borde de Kotlin.
class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.child, this.onTap, this.radius = 18, this.color = AppColors.white, this.border = AppColors.staffBorder, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final Color border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => AppCard(onTap: onTap, radius: radius, color: color, borderColor: border, padding: padding, child: child);
}

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});
  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getIt<AgendaViewModel>().refreshStaffOverview();
      if (getIt<SessionViewModel>().canOpen('/s/alerts')) getIt<ReportViewModel>().refreshAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agendaVm = getIt<AgendaViewModel>();
    final productionVm = getIt<ProductionViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    final storesVm = getIt<StoreSearchViewModel>();
    final reportVm = getIt<ReportViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([agendaVm, productionVm, sessionVm, storesVm, reportVm]),
      builder: (context, _) {
        final agenda = agendaVm.state.agenda;
        final next = agenda.where((a) => a.status != AgendaStatus.done).firstOrNull;
        final orders = productionVm.productionOrders;
        final canAgenda = sessionVm.canOpen('/s/agenda');
        final canProduction = sessionVm.canOpen('/s/production');
        final actions = [
          if (sessionVm.canOpen('/s/patients/new')) (LucideIcons.users, 'Nuevo paciente', '/s/patients/new'),
          if (sessionVm.canOpen('/s/scanner')) (LucideIcons.scan, 'Escanear', '/s/scanner'),
          if (sessionVm.canOpen('/s/quote')) (LucideIcons.fileText, 'Cotización', '/s/quote'),
          if (sessionVm.canOpen('/s/sale')) (LucideIcons.creditCard, 'Nueva venta', '/s/quote'),
          if (canProduction && !sessionVm.canOpen('/s/sale')) (LucideIcons.briefcase, 'Órdenes', '/s/production'),
        ];
        return StaffScaffold(
          tab: StaffTab.home,
          topBar: StaffTopBar(
            title: '${_greeting()}, ${sessionVm.firstName}',
            eyebrow: storesVm.staffStoreName,
            trailing: sessionVm.canOpen('/s/alerts') ? StaffBell(onTap: () => context.push('/s/alerts')) : null,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              StaffHero(
                background: AppColors.staffHero,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_agendaDateLabel(agendaVm.state.date), style: AppFonts.inter(fontSize: 11, color: AppColors.slate300, letterSpacing: 1.54)),
                          const SizedBox(height: 10),
                          Text('Tu jornada, de un vistazo', style: AppFonts.inter(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: -0.9)),
                          const SizedBox(height: 6),
                          Text('Todo listo para comenzar.', style: AppFonts.inter(fontSize: 13, color: AppColors.slate300)),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.staffChip, shape: BoxShape.circle),
                      child: Text(sessionVm.initials, style: AppFonts.inter(fontSize: 10, color: AppColors.staffHeader)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (agendaVm.state.error != null) ErrorBanner(agendaVm.state.error),
              if (productionVm.state.error != null) ErrorBanner(productionVm.state.error),
              if (canAgenda || canProduction)
                Row(
                  children: [
                    if (canAgenda)
                      Expanded(
                        child: _StatCard(
                          icon: LucideIcons.calendar,
                          value: '${agenda.length}',
                          title: 'Citas de hoy',
                          subtitle: '${agenda.where((a) => a.status != AgendaStatus.done).length} pendientes',
                          onTap: () => context.go('/s/agenda'),
                        ),
                      ),
                    if (canAgenda && canProduction) const SizedBox(width: 14),
                    if (canProduction)
                      Expanded(
                        child: _StatCard(
                          icon: LucideIcons.briefcase,
                          value: '${orders.where((o) => o.stage != ProductionStage.delivered).length}',
                          title: 'En producción',
                          subtitle: '${orders.where((o) => o.stage == ProductionStage.ready).length} por entregar',
                          onTap: () => context.push('/s/production'),
                        ),
                      ),
                  ],
                ),
              if (canAgenda) ...[
                const SizedBox(height: 24),
                StaffSectionTitle('Próxima atención', action: 'Ver agenda', onAction: () => context.go('/s/agenda')),
                const SizedBox(height: 12),
                if (agendaVm.state.loading && agenda.isEmpty)
                  Text('Cargando la agenda...', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400))
                else if (next == null)
                  Text('No hay más citas para hoy.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400))
                else
                  _StaffCard(
                    onTap: () => context.push('/s/patient/${next.patientId}'),
                    child: Row(
                      children: [
                        StaffInitials(_initialsOf(next.name)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StaffPill(switch (next.status) {
                                AgendaStatus.waiting => 'En sala de espera',
                                AgendaStatus.pending => 'Por confirmar',
                                _ => 'Confirmada',
                              }),
                              const SizedBox(height: 4),
                              Text(next.name, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                              const SizedBox(height: 4),
                              Text('${next.time} · ${next.service}', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 22, color: AppColors.staffInk),
                      ],
                    ),
                  ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                const StaffSectionTitle('Acciones frecuentes'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final (i, (icon, label, route)) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _StaffCard(
                          radius: 16,
                          padding: EdgeInsets.zero,
                          onTap: () => context.push(route),
                          child: SizedBox(
                            height: 82,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: 22, color: AppColors.staffInk),
                                const SizedBox(height: 7),
                                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 10, color: AppColors.staffInk)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (sessionVm.canOpen('/s/alerts')) ...[
                const SizedBox(height: 18),
                _AlertsCard(
                  stock: reportVm.state.lowStock.length,
                  production: reportVm.alerts.where((a) => a.kind == 'Producción').length,
                  onTap: () => context.push('/s/alerts'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _StaffCard(
      onTap: onTap,
      child: SizedBox(
        height: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaffIconTile(icon),
                const Spacer(),
                Text(value, style: AppFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.staffInk, height: 1)),
              ],
            ),
            const Spacer(),
            Text(title, style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.stock, required this.production, required this.onTap});
  final int stock;
  final int production;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = stock + production;
    return _StaffCard(
      radius: 16,
      color: AppColors.staffBlue50,
      border: AppColors.staffBlue200,
      onTap: onTap,
      child: Row(
        children: [
          const StaffIconTile(LucideIcons.bell, size: 37, background: AppColors.lavender, color: AppColors.staffInk, radius: 12),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (total) { 0 => 'Sin alertas por ahora', 1 => '1 alerta requiere atención', _ => '$total alertas requieren atención' },
                  style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk),
                ),
                Text('$stock de stock · $production de producción', style: AppFonts.inter(fontSize: 11, color: AppColors.staffMuted)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 22, color: AppColors.staffInk),
        ],
      ),
    );
  }
}

/// Rango de la semana mostrada con flechas para ir a la anterior o a la siguiente.
class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.days,
    required this.canGoBack,
    required this.canGoForward,
    required this.showToday,
    required this.onBack,
    required this.onForward,
    required this.onToday,
  });

  final List<DateTime> days;
  final bool canGoBack;
  final bool canGoForward;
  final bool showToday;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onToday;

  String _label() {
    final first = days.first;
    final last = days.last;
    String month(DateTime d) => DateFormat('MMM', 'es').format(d).replaceAll('.', '');
    if (first.month == last.month) return '${first.day} – ${last.day} ${month(last)} ${last.year}';
    return '${first.day} ${month(first)} – ${last.day} ${month(last)} ${last.year}';
  }

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, bool enabled, VoidCallback onTap, String tooltip) => IconButton(
          tooltip: tooltip,
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 20),
          color: AppColors.staffAccent,
          disabledColor: AppColors.slate300,
          visualDensity: VisualDensity.compact,
        );
    return Row(
      children: [
        arrow(LucideIcons.chevronLeft, canGoBack, onBack, 'Semana anterior'),
        Expanded(
          child: Column(
            children: [
              Text(_label(), textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.staffInk)),
              if (showToday)
                GestureDetector(
                  onTap: onToday,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Volver a hoy', style: AppFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
                  ),
                ),
            ],
          ),
        ),
        arrow(LucideIcons.chevronRight, canGoForward, onForward, 'Semana siguiente'),
      ],
    );
  }
}

class StaffAgendaScreen extends StatefulWidget {
  const StaffAgendaScreen({super.key});

  @override
  State<StaffAgendaScreen> createState() => _StaffAgendaScreenState();
}

class _StaffAgendaScreenState extends State<StaffAgendaScreen> {
  int filter = 0;
  static const _weekDays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB'];
  static final _filters = <(String, bool Function(AgendaItem))>[
    ('Todas', (_) => true),
    ('En espera', (item) => item.status == AgendaStatus.waiting),
    ('Confirmadas', (item) => item.status == AgendaStatus.confirmed),
    ('Retiros', (item) => item.status == AgendaStatus.pickup),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<AgendaViewModel>().refreshStaffAgenda(); });
  }

  @override
  Widget build(BuildContext context) {
    final agendaVm = getIt<AgendaViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    final storesVm = getIt<StoreSearchViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([agendaVm, sessionVm, storesVm]),
      builder: (context, _) {
        final agenda = agendaVm.state.agenda;
        final date = agendaVm.state.date;
        final days = agendaVm.agendaWeek;
        final waiting = agenda.where((a) => a.status == AgendaStatus.waiting).toList();
        final done = agenda.where((a) => a.status == AgendaStatus.done).length;
        final predicate = _filters[filter].$2;
        final next = agenda.where((a) => a.status != AgendaStatus.waiting && predicate(a)).toList();
        final isToday = StoreTime.isoDay(date) == StoreTime.isoDay(StoreTime.today());
        return StaffScaffold(
          tab: StaffTab.agenda,
          topBar: StaffTopBar(
            title: 'Citas y agenda',
            eyebrow: storesVm.staffStoreName,
            trailing: sessionVm.canOpen('/s/alerts') ? StaffBell(onTap: () => context.push('/s/alerts')) : null,
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                children: [
                  StaffHero(
                    background: const Color(0xFF242E78),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_agendaDateLabel(date), style: AppFonts.inter(fontSize: 9, color: AppColors.slate300, letterSpacing: 1.2)),
                              const SizedBox(height: 8),
                              Text(
                                '${agenda.length} ${agenda.length == 1 ? 'paciente' : 'pacientes'}${isToday ? ' hoy' : ''}',
                                style: AppFonts.inter(fontSize: 20, color: AppColors.white),
                              ),
                              const SizedBox(height: 8),
                              Text('$done consultas completadas · ${waiting.length} en sala de espera', style: AppFonts.inter(fontSize: 11, color: AppColors.slate300)),
                            ],
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(10)),
                          child: Text('${agenda.length}', style: AppFonts.inter(fontSize: 13, color: AppColors.staffHeader)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WeekNavigator(
                    days: days,
                    canGoBack: agendaVm.canShowPreviousWeek && !agendaVm.state.loading,
                    canGoForward: agendaVm.canShowNextWeek && !agendaVm.state.loading,
                    showToday: agendaVm.weekOffset != 0,
                    onBack: () => agendaVm.shiftAgendaWeek(-1),
                    onForward: () => agendaVm.shiftAgendaWeek(1),
                    onToday: agendaVm.showTodayAgenda,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < days.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => agendaVm.refreshStaffAgenda(date: days[i]),
                            child: Builder(builder: (context) {
                              final selected = StoreTime.isoDay(days[i]) == StoreTime.isoDay(date);
                              return Container(
                                height: 56,
                                decoration: BoxDecoration(color: selected ? AppColors.staffAccent : AppColors.white, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_weekDays[i], style: AppFonts.inter(fontSize: 8, color: selected ? AppColors.white : AppColors.staffInk)),
                                    Text('${days[i].day}', style: AppFonts.inter(fontSize: 16, color: selected ? AppColors.white : AppColors.staffInk)),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (i, (label, test)) in _filters.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          StaffChip('$label (${agenda.where(test).length})', selected: filter == i, onTap: () => setState(() => filter = i)),
                        ],
                      ],
                    ),
                  ),
                  if (filter != 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.listFilter, size: 14, color: AppColors.staffAccent),
                        const SizedBox(width: 6),
                        Text('Filtro activo: ${_filters[filter].$1.toLowerCase()}', style: AppFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
                      ],
                    ),
                  ],
                  if (agendaVm.state.loading) ...[
                    const SizedBox(height: 16),
                    Text('Cargando la agenda...', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                  ],
                  if (agendaVm.state.error != null) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(agendaVm.state.error),
                    TextButton(onPressed: agendaVm.refreshStaffAgenda, child: const Text('Reintentar')),
                  ],
                  if (filter == 0 || filter == 1) ...[
                    const SizedBox(height: 26),
                    const StaffSectionTitle('En sala de espera', action: 'Sala 1'),
                    const SizedBox(height: 12),
                    for (final item in waiting)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StaffCard(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/s/patient/${item.patientId}'),
                                child: Row(
                                  children: [
                                    StaffInitials(_initialsOf(item.name)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const StaffPill('En sala', icon: LucideIcons.clock),
                                          const SizedBox(height: 4),
                                          Text(item.name, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                                          const SizedBox(height: 4),
                                          Text('${item.time} · ${item.service}', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                                        ],
                                      ),
                                    ),
                                    const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
                                  ],
                                ),
                              ),
                              if (sessionVm.canOpen('/s/clinical') && item.appointmentId != null) ...[
                                const SizedBox(height: 14),
                                StaffButton(
                                  label: 'Iniciar atención clínica',
                                  icon: LucideIcons.eye,
                                  height: 48,
                                  onPressed: () => context.push(Uri(path: '/s/clinical', queryParameters: {'patientId': item.patientId, 'appointmentId': item.appointmentId!}).toString()),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (filter != 1) ...[
                    const SizedBox(height: 26),
                    StaffSectionTitle('Siguientes citas', action: '${next.length} por atender'),
                    const SizedBox(height: 12),
                    for (final item in next)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: _AgendaRow(item, onTap: () => context.push('/s/patient/${item.patientId}'))),
                  ],
                ],
              ),
              Positioned(
                right: 16,
                bottom: 22,
                child: StaffFab(text: 'Nueva cita', onTap: () => context.push('/s/appointments/new')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow(this.item, {required this.onTap});
  final AgendaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _StaffCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 66,
            height: 60,
            decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.time, style: AppFonts.inter(fontSize: 15, color: AppColors.staffInk)),
                Text(item.duration, style: AppFonts.inter(fontSize: 9, color: AppColors.staffMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                switch (item.status) {
                  AgendaStatus.confirmed => const StaffPill('Confirmada'),
                  AgendaStatus.pending => const StaffPill('Por confirmar', icon: LucideIcons.clock),
                  AgendaStatus.pickup => const StaffPill('Retiro', icon: LucideIcons.package),
                  _ => const StaffPill('Atendida'),
                },
                const SizedBox(height: 4),
                Text(item.name, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                const SizedBox(height: 4),
                Text(item.service, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
        ],
      ),
    );
  }
}

class StaffPatientsScreen extends StatefulWidget {
  const StaffPatientsScreen({super.key});

  @override
  State<StaffPatientsScreen> createState() => _StaffPatientsScreenState();
}

class _StaffPatientsScreenState extends State<StaffPatientsScreen> {
  String query = '';
  int filter = 0;
  static const tints = [AppColors.lavender, Color(0xFFDBEAFE), Color(0xFFF3F4FF), Color(0xFFE0E7FF)];
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<AgendaViewModel>().refreshStaffOverview(); });
  }

  @override
  Widget build(BuildContext context) {
    final agendaVm = getIt<AgendaViewModel>();
    final patientsVm = getIt<StaffPatientsViewModel>();
    final productionVm = getIt<ProductionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([agendaVm, patientsVm, productionVm]),
      builder: (context, _) {
        final patients = patientsVm.state.patients.where((patient) {
          final q = query.trim().toLowerCase();
          final matches = filter == 0 || (filter == 1 && agendaVm.waitingPatientIds.contains(patient.id)) || (filter == 2 && productionVm.workshopPatientIds.contains(patient.id));
          return matches && (q.isEmpty || patient.fullName.toLowerCase().contains(q) || patient.email.toLowerCase().contains(q) || patient.phone.contains(q));
        }).toList();
        final waitingCount = patientsVm.state.patients.where((p) => agendaVm.waitingPatientIds.contains(p.id)).length;
        final workshopCount = patientsVm.state.patients.where((p) => productionVm.workshopPatientIds.contains(p.id)).length;
        final chips = ['Todos (${patientsVm.state.patients.length})', 'En atención ($waitingCount)', 'En taller ($workshopCount)'];
        return StaffScaffold(
          tab: StaffTab.patients,
          topBar: StaffTopBar(
            title: 'Pacientes',
            trailing: StaffCircleAction(icon: LucideIcons.plus, onTap: () => context.push('/s/patients/new')),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  StaffHero(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expedientes de pacientes', style: AppFonts.inter(fontSize: 18, color: AppColors.white)),
                        const SizedBox(height: 8),
                        Text('Fichas optométricas, recetas y seguimientos al día.', style: AppFonts.inter(fontSize: 11, color: AppColors.slate300)),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(child: _StatColumn('${patientsVm.state.patients.length}', 'Total pacientes')),
                            Expanded(child: _StatColumn('${patientsVm.newPatientsThisMonth}', 'Nuevos este mes', color: const Color(0xFF34D399))),
                            Expanded(child: _StatColumn(patientsVm.state.patientsWithRecords?.toString() ?? '—', 'Con ficha vigente')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SearchField(controller: _search, placeholder: 'Buscar por nombre, correo o teléfono', onChanged: (value) => setState(() => query = value)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < chips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          StaffChip(chips[i], selected: filter == i, onTap: () => setState(() => filter = i)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const StaffSectionTitle('Pacientes recientes', action: 'Ordenar por fecha'),
                  const SizedBox(height: 12),
                  if (patientsVm.state.loading && patientsVm.state.patients.isEmpty)
                    Text('Cargando pacientes...', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                  if (patientsVm.state.error != null) ...[
                    ErrorBanner(patientsVm.state.error),
                    TextButton(onPressed: patientsVm.refreshStaffPatients, child: const Text('Reintentar')),
                  ],
                  if (patientsVm.state.summaryError != null) ...[
                    ErrorBanner(patientsVm.state.summaryError),
                    const SizedBox(height: 12),
                  ],
                  if (!patientsVm.state.loading && patientsVm.state.error == null && patients.isEmpty)
                    Text('No hay pacientes con esos criterios.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                  for (var index = 0; index < patients.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StaffCard(
                        onTap: () => context.push('/s/patient/${patients[index].id}'),
                        child: Row(
                          children: [
                            StaffInitials(patients[index].initials, size: 52, background: tints[index % tints.length], fontSize: 14),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(patients[index].fullName, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                                  const SizedBox(height: 3),
                                  Text(patients[index].email, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                                  const SizedBox(height: 3),
                                  Text(patients[index].note, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 22,
                child: StaffFab(text: 'Nuevo paciente', onTap: () => context.push('/s/patients/new')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(this.value, this.label, {this.color = AppColors.white});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppFonts.inter(fontSize: 18, color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppFonts.inter(fontSize: 9, color: AppColors.slate300)),
      ],
    );
  }
}

class StaffInventoryScreen extends StatefulWidget {
  const StaffInventoryScreen({super.key});
  @override
  State<StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends State<StaffInventoryScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getIt<CatalogViewModel>().refreshInventory();
      getIt<StoreSearchViewModel>().loadStores();
      if (getIt<SessionViewModel>().canOpen('/s/production')) getIt<ProductionViewModel>().refreshStaffOrders();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Se recarga al volver de una reposición o de una montura nueva.
  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) getIt<CatalogViewModel>().refreshInventory();
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    final storesVm = getIt<StoreSearchViewModel>();
    final productionVm = getIt<ProductionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([catalogVm, sessionVm, storesVm, productionVm]),
      builder: (context, _) {
        final state = catalogVm.state;
        final all = state.products;
        final q = _search.text.trim().toLowerCase();
        final rows = q.isEmpty
            ? all
            : all.where((item) {
                final frame = catalogVm.frameById(item.sku);
                return [item.name, item.sku, frame?.color, frame?.material].whereType<String>().any((v) => v.toLowerCase().contains(q));
              }).toList();
        final total = all.fold<int>(0, (sum, item) => sum + item.available);
        final low = all.where((item) => item.minimumStock != null && item.available <= item.minimumStock!).length;
        final canProduction = sessionVm.canOpen('/s/production');
        final open = productionVm.productionOrders.where((o) => o.stage != ProductionStage.delivered).toList();
        final actions = [
          if (sessionVm.canOpen('/s/inventory/new')) (LucideIcons.plus, 'Nueva montura', '/s/inventory/new'),
          if (sessionVm.canOpen('/s/movement')) (LucideIcons.box, 'Ingresar stock', '/s/movement'),
          if (sessionVm.canOpen('/s/alerts')) (LucideIcons.bell, 'Alertas', '/s/alerts'),
          if (canProduction) (LucideIcons.fileText, 'Órdenes', '/s/production'),
        ];
        return StaffScaffold(
          tab: StaffTab.inventory,
          topBar: StaffTopBar(title: 'Inventario', trailing: StaffCircleAction(icon: LucideIcons.scan, onTap: () => context.push('/s/scanner'))),
          body: RefreshIndicator(
            onRefresh: catalogVm.refreshInventory,
            child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
              StaffHero(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CONTROL DE STOCK · ${storesVm.staffStoreName.toUpperCase()}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppFonts.inter(fontSize: 8, color: AppColors.slate300, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text('Catálogo y stock', style: AppFonts.inter(fontSize: 18, color: AppColors.white)),
                      const SizedBox(height: 6),
                      Text('${all.length} modelos en el catálogo de la cadena.', style: AppFonts.inter(fontSize: 10, color: AppColors.slate300)),
                    ]),
                  ),
                  const Icon(LucideIcons.layoutGrid, size: 44, color: AppColors.staffSubtle),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.eye,
                    value: '$total',
                    title: 'En stock',
                    subtitle: '$low por reponer',
                    onTap: sessionVm.canOpen('/s/alerts') ? () => context.push('/s/alerts') : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: canProduction
                      ? _StatCard(
                          icon: LucideIcons.briefcase,
                          value: '${open.length}',
                          title: 'En taller / lab',
                          subtitle: '${open.where((o) => o.needsAttention).length} con retraso',
                          onTap: () => context.push('/s/production'),
                        )
                      : _StatCard(
                          icon: LucideIcons.briefcase,
                          value: '${all.where((item) => item.available == 0).length}',
                          title: 'Sin stock',
                          subtitle: 'modelos agotados aquí',
                        ),
                ),
              ]),
              const SizedBox(height: 12),
              SearchField(controller: _search, placeholder: 'Buscar modelo, SKU o color', onChanged: (_) => setState(() {})),
              const SizedBox(height: 26),
              StaffSectionTitle('Catálogo · ${rows.length} ${rows.length == 1 ? 'modelo' : 'modelos'}'),
              const SizedBox(height: 12),
              if (state.inventoryLoading && all.isEmpty)
                Text('Cargando...', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400))
              else if (state.inventoryError != null) ...[
                Text(state.inventoryError!, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                TextButton(onPressed: catalogVm.refreshInventory, child: const Text('Reintentar')),
              ] else if (rows.isEmpty)
                Text('No hay monturas que coincidan.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
              for (var i = 0; i < rows.length; i += 2) ...[
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final item in rows.skip(i).take(2)) ...[
                      if (item != rows[i]) const SizedBox(width: 14),
                      Expanded(child: _ProductCard(item, catalogVm.frameById(item.sku), onTap: () => _open('/s/product/${Uri.encodeComponent(item.sku)}'))),
                    ],
                    if (i + 1 >= rows.length) ...[const SizedBox(width: 14), const Expanded(child: SizedBox())],
                  ]),
                ),
                const SizedBox(height: 14),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                const StaffSectionTitle('Acciones rápidas'),
                const SizedBox(height: 12),
                Row(children: [
                  for (final (index, (icon, label, path)) in actions.indexed) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _StaffCard(
                        radius: 16,
                        padding: EdgeInsets.zero,
                        onTap: () => _open(path),
                        child: SizedBox(
                          height: 82,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(icon, size: 22, color: AppColors.staffInk),
                            const SizedBox(height: 7),
                            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 10, color: AppColors.staffInk)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ]),
              ],
            ]),
          ),
        );
      },
    );
  }
}

/// Etiqueta del stock de una montura en la óptica.
String _stockTag(ProductItem item) => item.available == 0
    ? 'Sin stock'
    : item.minimumStock != null && item.available <= item.minimumStock!
        ? 'Stock bajo'
        : 'Disponible';

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.item, this.frame, {required this.onTap});
  final ProductItem item;
  final FrameItem? frame;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tag = _stockTag(item);
    final detail = [frame?.color, frame?.material].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return _StaffCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(framePhotoFor(item.sku), height: 92, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 10),
        StaffPill(tag, icon: tag == 'Disponible' ? LucideIcons.check : LucideIcons.bell),
        const SizedBox(height: 8),
        Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
        const SizedBox(height: 4),
        Text(detail.isEmpty ? item.sku : detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 9, color: AppColors.slate400)),
        const Spacer(),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(item.price, style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.staffInk))),
          Text('${item.available} disp.', style: AppFonts.inter(fontSize: 9, color: item.available == 0 ? AppColors.errorRed : AppColors.staffGreen)),
        ]),
      ]),
    );
  }
}
class StaffMoreScreen extends StatelessWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionVm = getIt<SessionViewModel>();
    final productionVm = getIt<ProductionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([sessionVm, productionVm]),
      builder: (context, _) {
        final openOrders = productionVm.state.orders.where((o) => o.status != 'DELIVERED').length;
        return StaffScaffold(
          tab: StaffTab.more,
          topBar: const StaffTopBar(title: 'Más herramientas'),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Operación', style: AppFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (sessionVm.canOpen('/s/sale')) _Tool(Icons.credit_card, 'Ventas y pagos', 'Historial y nueva venta', () => context.push('/s/sale')),
                    if (sessionVm.canOpen('/s/quote')) _Tool(Icons.description_outlined, 'Cotizaciones', 'Pendientes y enviadas', () => context.push('/s/quote')),
                    if (sessionVm.canOpen('/s/production')) _Tool(Icons.work_outline, 'Órdenes de trabajo', 'Producción y entregas', () => context.push('/s/production'), badge: openOrders > 0 ? '$openOrders' : null),
                    if (sessionVm.canOpen('/s/clinical')) _Tool(Icons.visibility_outlined, 'Atención clínica', 'Evaluación y receta', () => context.push('/s/clinical')),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Gestión', style: AppFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (sessionVm.canOpen('/s/alerts')) _Tool(Icons.notifications_none, 'Alertas', 'Stock crítico y órdenes', () => context.push('/s/alerts')),
                    if (sessionVm.canOpen('/s/reports')) _Tool(Icons.bar_chart, 'Reportes', 'Ventas, producción e inventario del mes', () => context.push('/s/reports')),
                    if (sessionVm.canOpen('/s/admin/staff')) _Tool(Icons.person_outline, 'Personal', 'Altas, roles y accesos', () => context.push('/s/admin/staff')),
                    if (sessionVm.canOpen('/s/admin/suppliers')) _Tool(Icons.inventory_2_outlined, 'Proveedores', null, () => context.push('/s/admin/suppliers')),
                    if (sessionVm.canOpen('/s/admin/schedule')) _Tool(Icons.calendar_today_outlined, 'Horarios de atención', 'Abrir turnos para reservar', () => context.push('/s/admin/schedule')),
                    _Tool(Icons.settings_outlined, 'Configuración y permisos', sessionVm.session?.role.label, () => context.push('/s/settings')),
                    _Tool(Icons.help_outline, 'Ayuda y documentación', null, () => context.push('/s/info/help')),
                    _Tool(Icons.logout, 'Cerrar sesión', sessionVm.session?.email, () async { await sessionVm.logout(); }),
                  ],
                ),
              ),
            ],
          ),
        );
        },
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.icon, this.title, this.subtitle, this.onTap, {this.badge});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconTile(icon: icon, background: const Color(0xFFEEF2FF), color: AppColors.staffAccent),
      title: Text(title, style: AppFonts.inter(color: AppColors.staffInk)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: badge == null ? const Icon(Icons.chevron_right) : CircleAvatar(radius: 12, backgroundColor: AppColors.staffAccent, child: Text(badge!, style: const TextStyle(color: AppColors.white, fontSize: 11))),
    );
  }
}
