import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/demo_data.dart';
import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final next = DemoData.agenda.first;
    return StaffScaffold(
      tab: StaffTab.home,
      topBar: Container(
        color: AppColors.staffHeader,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MIÉRCOLES 20 JUN', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300, letterSpacing: 1.4)),
                Text('Tu jornada, de un vistazo', style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.white)),
                Text('Todo listo para comenzar.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate300)),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            onTap: () => context.push('/s/clinical'),
            child: Row(
              children: [
                const IconTile(icon: Icons.person_outline, background: AppColors.staffChip, color: AppColors.staffHeader),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(next.name, style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                      Text('${next.time} · ${next.service}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate400),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Stat('8', 'Citas hoy', () => context.go('/s/agenda'))),
              const SizedBox(width: 12),
              Expanded(child: _Stat('3', 'En taller', () => context.push('/s/production'))),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/s/alerts'),
            color: const Color(0xFFFFF7ED),
            child: const Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: Color(0xFFC2410C)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3 alertas requieren atención', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.staffInk)),
                      Text('Stock bajo y órdenes con retraso.', style: TextStyle(color: AppColors.staffMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Accesos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Link('Nuevo paciente', () => context.push('/s/patients/new')),
              _Link('Nueva cita', () => context.push('/s/appointments/new')),
              _Link('Evaluación', () => context.push('/s/evaluation')),
              _Link('Cotizar', () => context.push('/s/quote')),
              _Link('Escanear', () => context.push('/s/scanner')),
            ],
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
  static const filters = ['Todas', 'En espera', 'Confirmadas', 'Retiro'];

  @override
  Widget build(BuildContext context) {
    final items = DemoData.agenda.where((item) {
      return switch (filter) {
        1 => item.status == AgendaStatus.waiting,
        2 => item.status == AgendaStatus.confirmed,
        3 => item.status == AgendaStatus.pickup,
        _ => true,
      };
    }).toList();
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: Container(
        width: double.infinity,
        color: AppColors.staffHeader,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MIÉRCOLES 20 JUN', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300, letterSpacing: 1.2)),
                Text('8 pacientes hoy', style: GoogleFonts.inter(fontSize: 20, color: AppColors.white)),
                Text('2 consultas completadas · 1 en sala de espera', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate300)),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < filters.length; i++)
                ChoiceChip(label: Text(filters[i]), selected: filter == i, onSelected: (_) => setState(() => filter = i)),
            ],
          ),
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
    final products = DemoData.products.where((p) {
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

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final rut = TextEditingController();
  String reason = 'Primera consulta';

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    rut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.patients,
      topBar: StaffTopBar(title: 'Nuevo cliente', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('FICHA DIGITAL', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent, letterSpacing: 1)),
          Text('Registro rápido de paciente', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Camila Paz Morales')),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Teléfono móvil')),
          TextField(controller: rut, decoration: const InputDecoration(labelText: 'RUT / identificación')),
          const SizedBox(height: 12),
          Text('Motivo de consulta', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              for (final option in const ['Primera consulta', 'Control anual', 'Cambio de cristales', 'Molestia visual'])
                ChoiceChip(label: Text(option), selected: reason == option, onSelected: (_) => setState(() => reason = option)),
            ],
          ),
          const SizedBox(height: 16),
          SolidButton(
            label: 'Guardar paciente',
            onPressed: () {
              if (name.text.trim().isEmpty) {
                showAppMessage(context, 'Ingresa el nombre del paciente');
                return;
              }
              context.read<OptiFlowController>().addStaffPatient(name: name.text, phone: phone.text, rut: rut.text, reason: reason);
              showAppMessage(context, 'Paciente registrado');
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class StaffPatientRecordScreen extends StatelessWidget {
  const StaffPatientRecordScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<OptiFlowController>().staffPatient(id);
    return StaffScaffold(
      tab: StaffTab.patients,
      topBar: StaffTopBar(title: patient.fullName, subtitle: 'ID #${patient.ficha}', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TELÉFONO  ${patient.phone}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                Text('ÚLTIMA VISITA  ${patient.lastVisit}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                Text('RUT  ${patient.rut} · ${patient.age == 0 ? '' : '${patient.age} años'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Última prescripción', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                Text('Dr. Sergio Ramos · 24 jun 2023', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                const SizedBox(height: 8),
                const Text('OD −1.25 / −0.50 x 175    OI −1.00 / −0.75 x 10'),
                const SizedBox(height: 6),
                Text('Monofocal Filtro Azul 1.60', style: GoogleFonts.inter(color: AppColors.staffAccent)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/s/clinical'),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: DateBadge(day: '20', month: 'JUN'),
              title: Text('Evaluación visual completa'),
              subtitle: Text('10:30 · Control visual integral'),
            ),
          ),
          const SizedBox(height: 12),
          SolidButton(label: 'Iniciar atención', onPressed: () => context.push('/s/clinical')),
          const SizedBox(height: 8),
          SolidButton(label: 'Nueva evaluación', background: AppColors.white, foreground: AppColors.staffAccent, border: AppColors.staffChip, onPressed: () => context.push('/s/evaluation')),
        ],
      ),
    );
  }
}

class NewAppointmentScreen extends StatelessWidget {
  const NewAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const times = ['10:30', '11:15', '12:00', '15:00', '16:30'];
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(title: 'Nueva cita', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('AGENDAMIENTO · PASO ÚNICO', style: GoogleFonts.inter(fontSize: 11, letterSpacing: 1, color: AppColors.staffAccent)),
          Text('Datos de la cita', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const ListTile(title: Text('Paciente'), subtitle: Text('Valentina Silva Morales')),
          const ListTile(title: Text('Servicio'), subtitle: Text('Examen de vista completo · 45 min')),
          const ListTile(title: Text('Sucursal'), subtitle: Text('Sucursal Centro · Av. Libertad 450')),
          const ListTile(title: Text('Fecha'), subtitle: Text('Miércoles, 20 de junio')),
          Wrap(spacing: 8, children: [for (final time in times) ActionChip(label: Text(time), onPressed: () => showAppMessage(context, 'Cita agendada para las $time'))]),
          const SizedBox(height: 16),
          SolidButton(label: 'Confirmar cita', onPressed: () { showAppMessage(context, 'Cita agendada para las 10:30'); context.pop(); }),
        ],
      ),
    );
  }
}

class ClinicalCareScreen extends StatelessWidget {
  const ClinicalCareScreen({super.key});

  static const stages = [
    ('En sala de espera', 'Llegada registrada a las 10:18'),
    ('En consulta optométrica', 'Anamnesis y biomicroscopía'),
    ('Pruebas de graduación', 'Refracción y test cromático'),
    ('Elección de armazón y cristales', 'Asesoría y medidas pupilares'),
    ('Derivado a taller / laboratorio', 'Biselado, corte y montaje'),
    ('Atención finalizada', 'Receta y comprobante clínico'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.watch<OptiFlowController>().clinicalStage;
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(title: 'Atención clínica', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atención en curso · Box 3 · Dra. Ramos', style: TextStyle(color: AppColors.white)),
                SizedBox(height: 8),
                Text('Valentina Silva Morales', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Ficha #OPT-2024-849 · 10:30', style: TextStyle(color: AppColors.slate300, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Actualizar estado de la consulta', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              Text('Paso ${current + 1} de 6', style: GoogleFonts.inter(color: AppColors.staffAccent, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                color: i == current ? const Color(0xFFF0F4FF) : AppColors.white,
                onTap: () => context.read<OptiFlowController>().setClinicalStage(i),
                child: Row(
                  children: [
                    Icon(i < current ? Icons.check_circle : Icons.circle_outlined, color: i == current ? AppColors.staffAccent : AppColors.slate300),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(stages[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)), Text(stages[i].$2, style: const TextStyle(fontSize: 12, color: AppColors.slate400))])),
                  ],
                ),
              ),
            ),
          SolidButton(label: 'Ir a evaluación', onPressed: () => context.push('/s/evaluation')),
        ],
      ),
    );
  }
}

class VisualEvaluationScreen extends StatelessWidget {
  const VisualEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(title: 'Evaluación visual', subtitle: 'Valentina Silva · OPT-2024-849', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(child: Text('20 Jun 2024 · Dr. C. Ramos')),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fórmula de cristales', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Monofocal Orgánico Alto Índice 1.60'),
                SizedBox(height: 6),
                Text('Tratamientos para fatiga digital y trabajo frente a pantallas.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/images/img_inv_clubmaster.png', width: 72, height: 72, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('RAY-BAN', style: TextStyle(fontSize: 11, color: AppColors.staffAccent)), Text('Clubmaster Classic Carey', style: TextStyle(fontWeight: FontWeight.w700)), Text('\$145.000 CLP')])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SolidButton(label: 'Generar orden de trabajo', onPressed: () => context.push('/s/work-order')),
        ],
      ),
    );
  }
}

class WorkOrderScreen extends StatelessWidget {
  const WorkOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Orden de trabajo', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('OT-2048 · Valentina Silva', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          Text('Venta #V-1038 · Entrega 28 de junio', style: GoogleFonts.inter(color: AppColors.staffAccent)),
          const SizedBox(height: 12),
          const AppCard(child: Text('Nova N-24 · Monofocal 1.60\nAntirreflejo + filtro azul\nCalibre 51 · DP 62')),
          const SizedBox(height: 16),
          SolidButton(label: 'Enviar a producción', onPressed: () => context.push('/s/production')),
        ],
      ),
    );
  }
}

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  ProductionStage stage = ProductionStage.inWorkshop;

  @override
  Widget build(BuildContext context) {
    final orders = DemoData.productionOrders.where((o) => o.stage == stage).toList();
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Producción', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final item in ProductionStage.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${item.label} (${DemoData.productionOrders.where((o) => o.stage == item).length})'),
                      selected: stage == item,
                      onSelected: (_) => setState(() => stage = item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty) const Text('No hay órdenes en esta etapa.'),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${order.code} · ${order.patient}'),
                  subtitle: Text('${order.detail}\n${order.due}'),
                  trailing: order.needsAttention ? const Icon(Icons.warning_amber, color: Colors.orange) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Cotización', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Productos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const AppCard(child: ListTile(contentPadding: EdgeInsets.zero, title: Text('Clubmaster Classic Carey'), subtitle: Text('Montura'), trailing: Text('\$145.000'))),
          const SizedBox(height: 8),
          const AppCard(child: ListTile(contentPadding: EdgeInsets.zero, title: Text('Monofocal 1.60 AR'), subtitle: Text('Cristales'), trailing: Text('\$89.000'))),
          const SizedBox(height: 8),
          AppCard(onTap: () => context.push('/s/scanner'), child: const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.add), title: Text('Agregar montura o lente'), subtitle: Text('Busca en el catálogo o escanea'))),
          const SizedBox(height: 16),
          const AppCard(child: Row(children: [Text('Total', style: TextStyle(fontSize: 16)), Spacer(), Text('\$234.000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))])),
          const SizedBox(height: 16),
          SolidButton(label: 'Continuar a venta', onPressed: () => context.push('/s/sale')),
        ],
      ),
    );
  }
}

class ConfirmSaleScreen extends StatelessWidget {
  const ConfirmSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Confirmar venta', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Resumen', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const AppCard(child: Text('Paciente: Valentina Silva\nClubmaster + monofocal 1.60\nEntrega estimada: 28 de junio\n\nTotal \$234.000')),
          const SizedBox(height: 16),
          SolidButton(label: 'Registrar pago', onPressed: () => context.push('/s/sale/done')),
        ],
      ),
    );
  }
}

class SaleDoneScreen extends StatelessWidget {
  const SaleDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Venta', onBack: () => context.go('/s/more')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.staffGreen, size: 72),
            const SizedBox(height: 12),
            Text('VENTA #V-1038', style: GoogleFonts.inter(color: AppColors.staffAccent, letterSpacing: 1.4)),
            Text('Venta confirmada', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
            const Text('El pago fue registrado correctamente.'),
            const SizedBox(height: 20),
            SolidButton(label: 'Crear orden de trabajo', onPressed: () => context.push('/s/work-order')),
            const SizedBox(height: 8),
            SolidButton(label: 'Volver al inicio', background: AppColors.white, foreground: AppColors.staffHeader, border: AppColors.staffChip, onPressed: () => context.go('/s/home')),
          ],
        ),
      ),
    );
  }
}

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Escanear producto', subtitle: 'Alinea el código dentro del marco', onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFF0B1224), borderRadius: BorderRadius.circular(24)),
                child: Container(width: 180, height: 180, decoration: BoxDecoration(border: Border.all(color: AppColors.white, width: 3), borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(height: 16),
            const AppCard(child: ListTile(contentPadding: EdgeInsets.zero, title: Text('Código detectado'), subtitle: Text('NV-N24-AZ'))),
            const SizedBox(height: 12),
            SolidButton(label: 'Ver producto', onPressed: () => context.push('/s/product/rb5154')),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final product = DemoData.product(id);
    final stock = context.watch<OptiFlowController>().stockOf(product);
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: product.name, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(product.image, height: 180, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          Text('${product.sku} · ${product.detail}', style: GoogleFonts.inter(color: AppColors.slate400)),
          Text(product.price, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          Text('$stock disponibles · ${product.location}', style: GoogleFonts.inter(color: AppColors.staffGreen)),
          Text('${product.size} · ${product.supplier}', style: GoogleFonts.inter(color: AppColors.slate500)),
          const SizedBox(height: 16),
          SolidButton(label: 'Ajustar stock', onPressed: () => context.push('/s/stock/${product.id}')),
          const SizedBox(height: 8),
          SolidButton(label: 'Nuevo movimiento', background: AppColors.white, foreground: AppColors.staffAccent, border: AppColors.staffChip, onPressed: () => context.push('/s/movement')),
        ],
      ),
    );
  }
}

class StockManagementScreen extends StatelessWidget {
  const StockManagementScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final product = DemoData.product(id);
    final app = context.watch<OptiFlowController>();
    final stock = app.stockOf(product);
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Control de lote', subtitle: product.sku, onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Calibre ${product.size} · ${product.location}'),
            const SizedBox(height: 20),
            Text('$stock', style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
            const Text('unidades disponibles'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SolidButton(label: '−1', onPressed: stock > 0 ? () => app.adjustStock(product.id, -1) : null)),
                const SizedBox(width: 12),
                Expanded(child: SolidButton(label: '+1', onPressed: () => app.adjustStock(product.id, 1))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewMovementScreen extends StatefulWidget {
  const NewMovementScreen({super.key});

  @override
  State<NewMovementScreen> createState() => _NewMovementScreenState();
}

class _NewMovementScreenState extends State<NewMovementScreen> {
  int qty = 1;
  String reason = 'Merma';

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Nuevo movimiento', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tipo de movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              for (final option in const ['Entrada', 'Salida', 'Merma', 'Conteo'])
                ChoiceChip(label: Text(option), selected: reason == option, onSelected: (_) => setState(() => reason = option)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(onPressed: qty > 1 ? () => setState(() => qty--) : null, icon: const Icon(Icons.remove)),
              Text('$qty', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              IconButton(onPressed: () => setState(() => qty++), icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 16),
          SolidButton(
            label: 'Registrar movimiento',
            onPressed: () {
              context.read<OptiFlowController>().adjustStock('rb5154', reason == 'Entrada' ? qty : -qty);
              showAppMessage(context, 'Movimiento de $reason registrado');
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Alertas', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final alert in DemoData.alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () {
                  if (alert.kind == 'Inventario') {
                    context.push('/s/inventory');
                  } else {
                    context.push('/s/production');
                  }
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(alert.title),
                  subtitle: Text('${alert.kind} · ${alert.message}'),
                  trailing: Text(alert.action, style: const TextStyle(color: AppColors.staffAccent)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Reportes', subtitle: 'Junio 2025', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(18)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ventas totales', style: TextStyle(color: Colors.white70)),
                Text('\$8.460.200', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                Text('18% sobre el mes anterior', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in DemoData.reportBars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(height: 120 * bar, decoration: BoxDecoration(color: AppColors.staffAccent, borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Lun  Mar  Mié  Jue  Vie  Sáb  Dom', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SolidButton(label: 'Exportar reporte', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: () => showAppMessage(context, 'Reporte de junio listo para compartir.')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.onTap);
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.staffHeader)),
          Text(label, style: GoogleFonts.inter(color: AppColors.staffMuted)),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
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
