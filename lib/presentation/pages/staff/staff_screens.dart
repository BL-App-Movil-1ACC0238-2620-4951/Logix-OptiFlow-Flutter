import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/searchbooking/domain/agenda_item.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

export 'package:logix_optiflow/presentation/pages/staff/staff_care_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_evaluation_screen.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_insight_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_inventory_screens.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_record_screen.dart';
export 'package:logix_optiflow/presentation/pages/staff/staff_sale_screens.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});
  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<AgendaViewModel>().refreshStaffOverview(); });
  }

  @override
  Widget build(BuildContext context) {
    final agendaVm = getIt<AgendaViewModel>();
    final productionVm = getIt<ProductionViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    final storesVm = getIt<StoreSearchViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([agendaVm, productionVm, sessionVm, storesVm]),
      builder: (context, _) {
        final next = agendaVm.state.agenda.where((a) => a.status != AgendaStatus.done).firstOrNull;
        return StaffScaffold(
          tab: StaffTab.home,
          topBar: StaffTopBar(
            title: 'Hola, ${sessionVm.firstName}',
            eyebrow: storesVm.staffStoreName,
            trailing: sessionVm.canOpen('/s/alerts') ? IconButton(
              onPressed: () => context.push('/s/alerts'),
              icon: const Icon(Icons.notifications_none, color: AppColors.white),
            ) : null,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('EEEE d MMM', 'es').format(agendaVm.state.date).toUpperCase(), style: AppFonts.inter(fontSize: 11, color: AppColors.slate300, letterSpacing: 1.4)),
                          const SizedBox(height: 10),
                          Text('Tu jornada, de un vistazo', style: AppFonts.inter(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.white)),
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
              if (agendaVm.state.loading || productionVm.state.loading) const LinearProgressIndicator(),
              if (agendaVm.state.error != null) TextButton(onPressed: agendaVm.refreshStaffAgenda, child: Text(agendaVm.state.error!)),
              if (productionVm.state.error != null) TextButton(onPressed: productionVm.refreshStaffOrders, child: Text(productionVm.state.error!)),
              Row(
                children: [
                  if (sessionVm.canOpen('/s/agenda'))
                    Expanded(child: _Stat('${agendaVm.state.agenda.length}', 'Citas del día', () => context.go('/s/agenda'), detail: '${agendaVm.state.agenda.where((a) => a.status != AgendaStatus.done).length} pendientes', icon: Icons.calendar_today_outlined)),
                  if (sessionVm.canOpen('/s/agenda') && sessionVm.canOpen('/s/production')) const SizedBox(width: 14),
                  if (sessionVm.canOpen('/s/production'))
                    Expanded(child: _Stat('${productionVm.state.orders.where((o) => o.status != 'DELIVERED').length}', 'En producción', () => context.push('/s/production'), detail: '${productionVm.state.orders.where((o) => o.status == 'READY_FOR_DELIVERY').length} por entregar', icon: Icons.work_outline)),
                ],
              ),
              const SizedBox(height: 24),
              if (sessionVm.canOpen('/s/agenda')) ...[
              Row(
                children: [
                  Expanded(child: Text('Próxima atención', style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
                  GestureDetector(
                    onTap: () => context.go('/s/agenda'),
                    child: Text('Ver agenda', style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (next == null)
                const Text('No hay más citas para este día.')
              else
              AppCard(
                onTap: () => context.push('/s/patient/${next.patientId}'),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                      child: Text(next.name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase(), style: AppFonts.inter(fontSize: 11, color: AppColors.electric)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.staffBlue50, borderRadius: BorderRadius.circular(20)),
                            child: Text(next.status == AgendaStatus.waiting ? 'En sala de espera' : next.status == AgendaStatus.pending ? 'Por confirmar' : 'Confirmada', style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                          ),
                          const SizedBox(height: 4),
                          Text(next.name, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                          Text('${next.time} · ${next.service}', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.staffInk),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ],
              Text('Acciones frecuentes', style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (sessionVm.canOpen('/s/patients/new')) _Action(Icons.people_outline, 'Nuevo paciente', () => context.push('/s/patients/new')),
                  if (sessionVm.canOpen('/s/scanner')) _Action(Icons.qr_code_scanner, 'Escanear', () => context.push('/s/scanner')),
                  if (sessionVm.canOpen('/s/quote')) _Action(Icons.description_outlined, 'Cotización', () => context.push('/s/quote')),
                  if (sessionVm.canOpen('/s/sale')) _Action(Icons.credit_card, 'Nueva venta', () => context.push('/s/sale')),
                  if (sessionVm.canOpen('/s/production') && !sessionVm.canOpen('/s/agenda')) _Action(Icons.work_outline, 'Producción', () => context.push('/s/production')),
                ],
              ),
              const SizedBox(height: 18),
              if (sessionVm.canOpen('/s/alerts'))
              AppCard(
                onTap: () => context.push('/s/alerts'),
                color: AppColors.staffBlue50,
                child: const Row(
                  children: [
                    IconTile(icon: Icons.notifications_none, background: AppColors.lavender, color: AppColors.staffInk, size: 37),
                    SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alertas de la óptica', style: TextStyle(fontSize: 12, color: AppColors.staffInk)),
                          Text('Stock bajo y órdenes con retraso.', style: TextStyle(fontSize: 11, color: AppColors.staffMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.staffInk),
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

class StaffAgendaScreen extends StatefulWidget {
  const StaffAgendaScreen({super.key});

  @override
  State<StaffAgendaScreen> createState() => _StaffAgendaScreenState();
}

class _StaffAgendaScreenState extends State<StaffAgendaScreen> {
  int filter = 0;
  static const filters = ['Todas', 'En espera', 'Confirmadas', 'Retiros'];

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
        final days = agendaVm.agendaWeek;
        final day = days.indexWhere((date) => StoreTime.isoDay(date) == StoreTime.isoDay(agendaVm.state.date));
        final items = agenda.where((item) {
          return switch (filter) {
            1 => item.status == AgendaStatus.waiting,
            2 => item.status == AgendaStatus.confirmed,
            3 => item.status == AgendaStatus.pickup,
            _ => true,
          };
        }).toList();
        int count(int index) => agenda.where((item) {
              return switch (index) {
                1 => item.status == AgendaStatus.waiting,
                2 => item.status == AgendaStatus.confirmed,
                3 => item.status == AgendaStatus.pickup,
                _ => true,
              };
            }).length;
        final waitingItems = items.where((item) => item.status == AgendaStatus.waiting).toList();
        final otherItems = items.where((item) => item.status != AgendaStatus.waiting).toList();
        return StaffScaffold(
          tab: StaffTab.agenda,
          topBar: StaffTopBar(
            title: 'Citas y agenda',
            eyebrow: storesVm.staffStoreName,
            trailing: sessionVm.canOpen('/s/alerts') ? IconButton(onPressed: () => context.push('/s/alerts'), icon: const Icon(Icons.notifications_none, color: AppColors.white)) : null,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                decoration: BoxDecoration(color: const Color(0xFF242E78), borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('EEEE d MMM', 'es').format(agendaVm.state.date).toUpperCase(), style: AppFonts.inter(fontSize: 9, color: AppColors.slate300, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text('${agenda.length} pacientes', style: AppFonts.inter(fontSize: 20, color: AppColors.white)),
                          const SizedBox(height: 8),
                          Text('${agenda.where((a) => a.status == AgendaStatus.done).length} consultas completadas · ${agenda.where((a) => a.status == AgendaStatus.waiting).length} en sala de espera', style: AppFonts.inter(fontSize: 11, color: AppColors.slate300)),
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
              Row(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => agendaVm.refreshStaffAgenda(date: days[i]),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: day == i ? AppColors.staffAccent : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: day == i ? AppColors.staffAccent : AppColors.staffBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('E', 'es').format(days[i]).replaceAll('.', '').toUpperCase(), style: AppFonts.inter(fontSize: 8, color: day == i ? AppColors.white : AppColors.staffInk)),
                              Text('${days[i].day}', style: AppFonts.inter(fontSize: 16, color: day == i ? AppColors.white : AppColors.staffInk)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < filters.length; i++)
                    ChoiceChip(
                      label: Text('${filters[i]} (${count(i)})'),
                      selected: filter == i,
                      onSelected: (_) => setState(() => filter = i),
                    ),
                ],
              ),
              if (filter != 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.filter_list, size: 14, color: AppColors.staffAccent),
                    const SizedBox(width: 6),
                    Text('Filtro activo: ${filters[filter].toLowerCase()}', style: AppFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (agendaVm.state.loading) const LinearProgressIndicator(),
              if (agendaVm.state.error != null) ...[
                Text(agendaVm.state.error!, style: const TextStyle(color: AppColors.errorRed)),
                TextButton(onPressed: agendaVm.refreshStaffAgenda, child: const Text('Reintentar')),
              ],
              if (!agendaVm.state.loading && agendaVm.state.error == null && items.isEmpty) const Text('No hay citas con este filtro para el día seleccionado.'),
              for (final item in [...waitingItems, ...otherItems]) ...[
                if (item == waitingItems.firstOrNull || item == otherItems.firstOrNull)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.status == AgendaStatus.waiting ? 'En sala de espera' : 'Siguientes citas', style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
                AppCard(
                  onTap: () => context.push('/s/patient/${item.patientId}'),
                  child: Row(
                    children: [
                      SizedBox(width: 54, child: Text(item.time, style: AppFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffHeader))),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                            Text('${item.duration} · ${item.service}', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      StatusCapsule(_statusLabel(item.status), color: AppColors.staffAccent, background: AppColors.staffBlue50),
                    ],
                  ),
                ),
                if (item.status == AgendaStatus.waiting && sessionVm.canOpen('/s/clinical') && item.appointmentId != null)
                  Padding(padding: const EdgeInsets.only(top: 8), child: SolidButton(label: 'Iniciar atención clínica', icon: Icons.visibility_outlined, onPressed: () => context.push(Uri(path: '/s/clinical', queryParameters: {'patientId': item.patientId, 'appointmentId': item.appointmentId!}).toString()))),
                const SizedBox(height: 8),
              ],
              SolidButton(label: 'Nueva cita', onPressed: () => context.push('/s/appointments/new')),
            ],
          ),
        );
        },
    );
  }

  String _statusLabel(AgendaStatus status) => switch (status) {
        AgendaStatus.waiting => 'En espera',
        AgendaStatus.confirmed => 'Confirmada',
        AgendaStatus.pending => 'Pendiente',
        AgendaStatus.pickup => 'Retiro',
        AgendaStatus.done => 'Atendida',
      };
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
        return StaffScaffold(
          tab: StaffTab.patients,
          topBar: StaffTopBar(
            title: 'Pacientes',
            trailing: IconButton(onPressed: () => context.push('/s/patients/new'), icon: const Icon(Icons.add, color: AppColors.white)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expedientes de pacientes', style: AppFonts.inter(fontSize: 18, color: AppColors.white)),
                    const SizedBox(height: 8),
                    Text('Fichas optométricas, recetas y seguimientos al día.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate300)),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _HeroStat('${patientsVm.state.patients.length}', 'Total pacientes')),
                        Expanded(child: _HeroStat('${patientsVm.newPatientsThisMonth}', 'Nuevos este mes', valueColor: const Color(0xFF34D399))),
                        Expanded(child: _HeroStat(patientsVm.state.patientsWithRecords?.toString() ?? '—', 'Con ficha vigente')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, correo o teléfono',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.staffBorder)),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _StaffChip(['Todos (${patientsVm.state.patients.length})', 'En atención (${patientsVm.state.patients.where((p) => agendaVm.waitingPatientIds.contains(p.id)).length})', 'En taller (${patientsVm.state.patients.where((p) => productionVm.workshopPatientIds.contains(p.id)).length})'][i], filter == i, () => setState(() => filter = i)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(child: Text('Pacientes recientes', style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
                  Text('Ordenar por fecha', style: AppFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
                ],
              ),
              const SizedBox(height: 12),
              if (patientsVm.state.loading) const LinearProgressIndicator(),
              if (patientsVm.state.error != null) ...[
                Text(patientsVm.state.error!, style: const TextStyle(color: AppColors.errorRed)),
                TextButton(onPressed: patientsVm.refreshStaffPatients, child: const Text('Reintentar')),
              ],
              if (patientsVm.state.summaryError != null) Text(patientsVm.state.summaryError!, style: const TextStyle(color: AppColors.errorRed)),
              if (!patientsVm.state.loading && patientsVm.state.error == null && patients.isEmpty) const Text('No hay pacientes con esos criterios.'),
              for (var index = 0; index < patients.length; index++) ...[
                AppCard(
                  onTap: () => context.push('/s/patient/${patients[index].id}'),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: tints[index % tints.length], borderRadius: BorderRadius.circular(16)),
                        child: Text(patients[index].initials, style: AppFonts.inter(fontSize: 14, color: AppColors.electric)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patients[index].name, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                            Text(patients[index].email, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                            Text(patients[index].note, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.staffInk),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              SolidButton(label: 'Nuevo paciente', icon: Icons.add, onPressed: () => context.push('/s/patients/new')),
            ],
          ),
        );
        },
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label, {this.valueColor = AppColors.white});
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppFonts.inter(fontSize: 18, color: valueColor)),
        const SizedBox(height: 4),
        Text(label, style: AppFonts.inter(fontSize: 10, color: AppColors.slate300)),
      ],
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.staffAccent : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.staffAccent : AppColors.lavender),
        ),
        child: Text(label, style: AppFonts.inter(fontSize: 12, color: selected ? AppColors.white : AppColors.staffInk)),
      ),
    );
  }
}

class StaffInventoryScreen extends StatefulWidget {
  const StaffInventoryScreen({super.key});
  @override
  State<StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends State<StaffInventoryScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getIt<CatalogViewModel>().refreshInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([catalogVm, sessionVm]),
      builder: (context, _) {
        final q = query.trim().toLowerCase();
        final products = catalogVm.state.products.where((item) => '${item.name} ${item.sku} ${item.detail}'.toLowerCase().contains(q)).toList();
        final total = catalogVm.state.products.fold<int>(0, (sum, item) => sum + item.available);
        final low = catalogVm.state.products.where((item) => item.minimumStock != null && item.available <= item.minimumStock!).length;
        return StaffScaffold(
          tab: StaffTab.inventory,
          topBar: StaffTopBar(title: 'Inventario de mi óptica', trailing: IconButton(onPressed: () => context.push('/s/scanner'), icon: const Icon(Icons.search, color: AppColors.white))),
          body: RefreshIndicator(
            onRefresh: catalogVm.refreshInventory,
            child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
              if (catalogVm.state.inventoryLoading) const LinearProgressIndicator(),
              if (catalogVm.state.inventoryError != null) ...[
                Text(catalogVm.state.inventoryError!, style: const TextStyle(color: AppColors.errorRed)),
                TextButton(onPressed: catalogVm.refreshInventory, child: const Text('Reintentar')),
              ],
              if (catalogVm.state.inventoryError == null && !catalogVm.state.inventoryLoading)
                AppCard(child: Row(children: [
                  Expanded(child: Text('$total unidades en stock', style: Theme.of(context).textTheme.titleMedium)),
                  Text('$low modelos con stock bajo'),
                ])),
              const SizedBox(height: 16),
              TextField(onChanged: (value) => setState(() => query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Nombre, SKU o material')),
              const SizedBox(height: 16),
              if (!catalogVm.state.inventoryLoading && catalogVm.state.inventoryError == null && products.isEmpty) const Text('No hay monturas con esos criterios.'),
              for (final product in products) ...[
                AppCard(onTap: () => context.push('/s/product/${Uri.encodeComponent(product.sku)}'), child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.remove_red_eye_outlined),
                  title: Text(product.name), subtitle: Text('${product.sku}\n${product.price} · ${product.available} unidades'),
                  trailing: const Icon(Icons.chevron_right),
                )),
                const SizedBox(height: 12),
              ],
              if (sessionVm.canOpen('/s/movement')) ...[
                const SizedBox(height: 12),
                SolidButton(label: 'Registrar ingreso de proveedor', icon: Icons.add, onPressed: () => context.push('/s/movement')),
              ],
            ]),
          ),
        );
        },
    );
  }
}
class StaffMoreScreen extends StatelessWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: sessionVm,
      builder: (context, _) {
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
                    if (sessionVm.canOpen('/s/production')) _Tool(Icons.work_outline, 'Órdenes de trabajo', 'Producción y entregas', () => context.push('/s/production'), badge: '5'),
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
                    if (sessionVm.canOpen('/s/alerts')) _Tool(Icons.notifications_none, 'Alertas', null, () => context.push('/s/alerts'), badge: '3'),
                    if (sessionVm.canOpen('/s/reports')) _Tool(Icons.bar_chart, 'Reportes', null, () => context.push('/s/reports')),
                    _Tool(Icons.settings_outlined, 'Configuración y permisos', sessionVm.session?.role.label, () => context.push('/s/settings')),
                    _Tool(Icons.help_outline, 'Ayuda y documentación', null, () => showAppMessage(context, 'Documentación en el README del proyecto.')),
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

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.onTap, {this.detail, this.icon});
  final String value;
  final String label;
  final String? detail;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 18, color: AppColors.staffAccent),
              const Spacer(),
              Text(value, style: AppFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.staffInk)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
          ],
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.staffInk),
            const SizedBox(height: 7),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 10, color: AppColors.staffInk)),
          ],
        ),
      ),
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
