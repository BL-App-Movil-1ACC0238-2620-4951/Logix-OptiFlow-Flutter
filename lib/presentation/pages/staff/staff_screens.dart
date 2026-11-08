import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/models.dart';
import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

export 'staff_care_screens.dart';
export 'staff_evaluation_screen.dart';
export 'staff_insight_screens.dart';
export 'staff_inventory_screens.dart';
export 'staff_record_screen.dart';
export 'staff_sale_screens.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final next = context.read<OptiFlowController>().agenda.first;
    return StaffScaffold(
      tab: StaffTab.home,
      topBar: StaffTopBar(
        title: 'Buenos días, Camila',
        subtitle: 'Óptica Visión Norte',
        trailing: IconButton(
          onPressed: () => context.push('/s/alerts'),
          icon: const Icon(Icons.notifications_none, color: AppColors.white),
        ),
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
                      Text('MIÉRCOLES 20 JUN', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300, letterSpacing: 1.4)),
                      const SizedBox(height: 10),
                      Text('Tu jornada, de un vistazo', style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 6),
                      Text('Todo listo para comenzar.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate300)),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.staffChip, shape: BoxShape.circle),
                  child: Text('CR', style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffHeader)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Stat('8', 'Citas de hoy', () => context.go('/s/agenda'), detail: '2 pendientes', icon: Icons.calendar_today_outlined)),
              const SizedBox(width: 14),
              Expanded(child: _Stat('12', 'En producción', () => context.push('/s/production'), detail: '3 por entregar', icon: Icons.work_outline)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Próxima atención', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
              GestureDetector(
                onTap: () => context.go('/s/agenda'),
                child: Text('Ver agenda', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffAccent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/s/patient/${next.patientId}'),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                  child: Text('VS', style: GoogleFonts.inter(fontSize: 11, color: AppColors.electric)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.staffBlue50, borderRadius: BorderRadius.circular(20)),
                        child: Text('En 15 minutos', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                      ),
                      const SizedBox(height: 4),
                      Text(next.name, style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                      Text('${next.time} · ${next.service}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.staffInk),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Acciones frecuentes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Action(Icons.people_outline, 'Nuevo paciente', () => context.push('/s/patients/new')),
              const SizedBox(width: 10),
              _Action(Icons.qr_code_scanner, 'Escanear', () => context.push('/s/scanner')),
              const SizedBox(width: 10),
              _Action(Icons.description_outlined, 'Cotización', () => context.push('/s/quote')),
              const SizedBox(width: 10),
              _Action(Icons.credit_card, 'Nueva venta', () => context.push('/s/sale')),
            ],
          ),
          const SizedBox(height: 18),
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
                      Text('3 alertas requieren atención', style: TextStyle(fontSize: 12, color: AppColors.staffInk)),
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
  }
}

class StaffAgendaScreen extends StatefulWidget {
  const StaffAgendaScreen({super.key});

  @override
  State<StaffAgendaScreen> createState() => _StaffAgendaScreenState();
}

class _StaffAgendaScreenState extends State<StaffAgendaScreen> {
  int filter = 0;
  int day = 2;
  static const filters = ['Todas', 'En espera', 'Confirmadas', 'Retiros'];
  static const days = [('LUN', '18'), ('MAR', '19'), ('MIÉ', '20'), ('JUE', '21'), ('VIE', '22'), ('SÁB', '23')];

  @override
  Widget build(BuildContext context) {
    final agenda = context.read<OptiFlowController>().agenda;
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
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(
        title: 'Citas y agenda',
        subtitle: 'Óptica Visión Norte',
        trailing: IconButton(onPressed: () => context.push('/s/alerts'), icon: const Icon(Icons.notifications_none, color: AppColors.white)),
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
                      Text('MIÉRCOLES 20 JUN', style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate300, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('8 pacientes hoy', style: GoogleFonts.inter(fontSize: 20, color: AppColors.white)),
                      const SizedBox(height: 8),
                      Text('2 consultas completadas · 1 en sala de espera', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300)),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(10)),
                  child: Text('8', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffHeader)),
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
                    onTap: () => setState(() => day = i),
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
                          Text(days[i].$1, style: GoogleFonts.inter(fontSize: 8, color: day == i ? AppColors.white : AppColors.staffInk)),
                          Text(days[i].$2, style: GoogleFonts.inter(fontSize: 16, color: day == i ? AppColors.white : AppColors.staffInk)),
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
                Text('Filtro activo: ${filters[filter].toLowerCase()}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          for (final item in items) ...[
            AppCard(
              onTap: () => context.push('/s/patient/${item.patientId}'),
              child: Row(
                children: [
                  SizedBox(width: 54, child: Text(item.time, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffHeader))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                        Text('${item.duration} · ${item.service}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                  StatusCapsule(_statusLabel(item.status), color: AppColors.staffAccent, background: AppColors.staffBlue50),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          SolidButton(label: 'Nueva cita', onPressed: () => context.push('/s/appointments/new')),
        ],
      ),
    );
  }

  String _statusLabel(AgendaStatus status) => switch (status) {
        AgendaStatus.waiting => 'En espera',
        AgendaStatus.confirmed => 'Confirmada',
        AgendaStatus.pending => 'Pendiente',
        AgendaStatus.pickup => 'Retiro',
        AgendaStatus.done => 'Lista',
      };
}

class StaffPatientsScreen extends StatefulWidget {
  const StaffPatientsScreen({super.key});

  @override
  State<StaffPatientsScreen> createState() => _StaffPatientsScreenState();
}

class _StaffPatientsScreenState extends State<StaffPatientsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final patients = context.watch<OptiFlowController>().staffPatients.where((p) {
      final q = query.trim().toLowerCase();
      return q.isEmpty || p.fullName.toLowerCase().contains(q) || p.rut.contains(q);
    }).toList();
    return StaffScaffold(
      tab: StaffTab.patients,
      topBar: StaffTopBar(
        title: 'Expedientes de pacientes',
        subtitle: 'Fichas optométricas, recetas y seguimientos al día.',
        trailing: IconButton(onPressed: () => context.push('/s/patients/new'), icon: const Icon(Icons.person_add_alt_1, color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Buscar nombre o RUT',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          for (final patient in patients) ...[
            AppCard(
              onTap: () => context.push('/s/patient/${patient.id}'),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: AppColors.staffChip, child: Text(patient.initials, style: const TextStyle(color: AppColors.staffHeader, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                        Text(patient.note, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
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
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final products = context.read<OptiFlowController>().products.where((p) {
      final q = query.toLowerCase();
      return q.isEmpty || p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
    }).toList();
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: const StaffTopBar(title: 'Catálogo y taller óptico', subtitle: 'Referencias, lentes en laboratorio y pedidos.'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(hintText: 'Buscar modelo, SKU o marca', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty) const Text('Sin modelos en esta categoría.'),
          for (final product in products) ...[
            AppCard(
              onTap: () => context.push('/s/product/${product.id}'),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(product.image, width: 64, height: 64, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                        Text('${product.sku} · ${product.detail}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                        Text('${app.stockOf(product)} disp. · ${product.tag}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class StaffMoreScreen extends StatelessWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: const StaffTopBar(title: 'Más herramientas'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Operación', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Tool(Icons.credit_card, 'Ventas y pagos', 'Historial y nueva venta', () => context.push('/s/sale')),
                _Tool(Icons.description_outlined, 'Cotizaciones', 'Pendientes y enviadas', () => context.push('/s/quote')),
                _Tool(Icons.work_outline, 'Órdenes de trabajo', 'Producción y entregas', () => context.push('/s/production'), badge: '5'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Gestión', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Tool(Icons.notifications_none, 'Alertas', null, () => context.push('/s/alerts'), badge: '3'),
                _Tool(Icons.bar_chart, 'Reportes', null, () => context.push('/s/reports')),
                _Tool(Icons.settings_outlined, 'Configuración y permisos', null, () => context.push('/p/settings?staff=true')),
                _Tool(Icons.help_outline, 'Ayuda y documentación', null, () => showAppMessage(context, 'Documentación en el README del proyecto.')),
                _Tool(Icons.person_outline, 'Vista paciente', 'Cambiar de experiencia', () => context.go('/p/home')),
              ],
            ),
          ),
        ],
      ),
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
              Text(value, style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.staffInk)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
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
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffInk)),
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
      title: Text(title, style: GoogleFonts.inter(color: AppColors.staffInk)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: badge == null ? const Icon(Icons.chevron_right) : CircleAvatar(radius: 12, backgroundColor: AppColors.staffAccent, child: Text(badge!, style: const TextStyle(color: AppColors.white, fontSize: 11))),
    );
  }
}
