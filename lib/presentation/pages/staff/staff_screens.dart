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
  int filter = 0;
  static const tints = [AppColors.lavender, Color(0xFFDBEAFE), Color(0xFFF3F4FF), Color(0xFFE0E7FF)];

  @override
  Widget build(BuildContext context) {
    final patients = context.watch<OptiFlowController>().staffPatients.where((patient) {
      final q = query.trim().toLowerCase();
      return q.isEmpty || patient.fullName.toLowerCase().contains(q) || patient.rut.contains(q) || patient.phone.contains(q);
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
                Text('Expedientes de pacientes', style: GoogleFonts.inter(fontSize: 18, color: AppColors.white)),
                const SizedBox(height: 8),
                Text('Fichas optométricas, recetas y seguimientos al día.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate300)),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(child: _HeroStat('1.248', 'Total pacientes')),
                    Expanded(child: _HeroStat('34', 'Nuevos este mes', valueColor: Color(0xFF34D399))),
                    Expanded(child: _HeroStat('890', 'Con ficha vigente')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, RUT o teléfono',
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
                  _StaffChip(['Todos (1.248)', 'En atención (1)', 'En taller (12)'][i], filter == i, () => setState(() => filter = i)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: Text('Pacientes recientes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
              Text('Ordenar por fecha', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
            ],
          ),
          const SizedBox(height: 12),
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
                    child: Text(patients[index].initials, style: GoogleFonts.inter(fontSize: 14, color: AppColors.electric)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patients[index].name, style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                        Text(patients[index].rut, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                        Text(patients[index].note, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
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
        Text(value, style: GoogleFonts.inter(fontSize: 18, color: valueColor)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate300)),
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
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: selected ? AppColors.white : AppColors.staffInk)),
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
  int category = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final all = app.products;
    final stockTotal = all.fold<int>(0, (sum, product) => sum + app.stockOf(product));
    final q = query.trim().toLowerCase();
    final products = category == 0
        ? all.where((product) => q.isEmpty || product.name.toLowerCase().contains(q) || product.sku.toLowerCase().contains(q)).toList()
        : all.where((_) => false).toList();
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(
        title: 'Inventario',
        trailing: IconButton(onPressed: () => context.push('/s/scanner'), icon: const Icon(Icons.qr_code_scanner, color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTROL DE STOCK · ACTUALIZADO HOY', style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate300, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text('Catálogo y taller óptico', style: GoogleFonts.inter(fontSize: 18, color: AppColors.white)),
                      const SizedBox(height: 6),
                      Text('Referencias, lentes en laboratorio y pedidos.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate300)),
                    ],
                  ),
                ),
                const Icon(Icons.grid_view, color: Color(0xFFB7C4FF), size: 44),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InvStat(Icons.remove_red_eye_outlined, '${300 + stockTotal + 29}', 'En stock', '8 por reponer', null)),
              const SizedBox(width: 14),
              Expanded(child: _InvStat(Icons.work_outline, '12', 'En taller / lab', '3 con entrega hoy', () => context.push('/s/production'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  style: GoogleFonts.inter(color: AppColors.white),
                  cursorColor: AppColors.white,
                  decoration: InputDecoration(
                    hintText: 'Buscar modelo, SKU o marca',
                    hintStyle: GoogleFonts.inter(color: AppColors.white.withValues(alpha: 0.9), fontSize: 14),
                    prefixIcon: const Icon(Icons.filter_list, color: AppColors.white, size: 18),
                    suffixIcon: const Icon(Icons.search, color: AppColors.white, size: 18),
                    filled: true,
                    fillColor: AppColors.staffAccent,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.staffAccent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => context.push('/s/scanner'),
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(width: 48, height: 48, child: Icon(Icons.qr_code_scanner, color: AppColors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _StaffChip(['Armazones', 'Gafas de sol', 'Lentes de contacto', 'Cristales'][i], category == i, () => setState(() => category = i)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Catálogo en vitrina · ${products.length} modelos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          if (products.isEmpty) Text('Sin modelos en esta categoría.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
          for (var i = 0; i < products.length; i += 2) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ProductCard(products[i], app.stockOf(products[i]))),
                const SizedBox(width: 14),
                Expanded(child: i + 1 < products.length ? _ProductCard(products[i + 1], app.stockOf(products[i + 1])) : const SizedBox()),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          Text('Acciones rápidas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Quick(Icons.add, 'Ingresar stock', () => context.push('/s/movement')),
              const SizedBox(width: 10),
              _Quick(Icons.chevron_right, 'Traslado', () => context.push('/s/stock/rb5154')),
              const SizedBox(width: 10),
              _Quick(Icons.check, 'Auditoría', () => context.push('/s/stock/rb5154')),
              const SizedBox(width: 10),
              _Quick(Icons.description_outlined, 'Órdenes', () => context.push('/s/production')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvStat extends StatelessWidget {
  const _InvStat(this.icon, this.value, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.staffAccent),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.product, this.available);
  final ProductItem product;
  final int available;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/s/product/${product.id}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(product.image, height: 92, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(20)),
            child: Text(product.tag, style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
          ),
          const SizedBox(height: 8),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          const SizedBox(height: 4),
          Text(product.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text(product.price, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.staffInk))),
              Text('$available disp.', style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffGreen)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
