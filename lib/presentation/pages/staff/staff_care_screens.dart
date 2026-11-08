import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/production_order.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final rut = TextEditingController();
  int reason = 0;

  static const reasons = [
    (Icons.remove_red_eye_outlined, 'Primera consulta'),
    (Icons.calendar_today_outlined, 'Control anual'),
    (Icons.grid_view, 'Cambio de cristales'),
    (Icons.help_outline, 'Molestia visual'),
  ];

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
      topBar: StaffTopBar(title: 'Nuevo Cliente', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const IconTile(icon: Icons.description_outlined, background: AppColors.white, color: AppColors.staffHeader, size: 36, iconSize: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FICHA DIGITAL', style: GoogleFonts.inter(fontSize: 11, color: AppColors.skyTint, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text('Registro rápido de paciente', style: GoogleFonts.inter(fontSize: 18, color: AppColors.white)),
                      const SizedBox(height: 6),
                      Text('Ingresa los datos indispensables para abrir su ficha clínica.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _Label('Nombre completo'),
          const SizedBox(height: 10),
          TextField(controller: name, decoration: _field('Camila Paz Morales', Icons.person_outline)),
          const SizedBox(height: 20),
          const _Label('Teléfono móvil'),
          const SizedBox(height: 10),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _field('+56 9 8745 9210', Icons.phone_outlined)),
          const SizedBox(height: 20),
          const _Label('RUT / identificación'),
          const SizedBox(height: 10),
          TextField(controller: rut, decoration: _field('18.942.105-K', Icons.credit_card_outlined)),
          const SizedBox(height: 28),
          Text('Motivo de consulta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          for (var row = 0; row < 2; row++) ...[
            Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(child: _ReasonChip(reasons[row * 2 + col].$1, reasons[row * 2 + col].$2, reason == row * 2 + col, () => setState(() => reason = row * 2 + col))),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          SolidButton(
            label: 'Guardar paciente',
            icon: Icons.check,
            onPressed: () {
              if (name.text.trim().isEmpty) {
                showAppMessage(context, 'Ingresa el nombre del paciente');
                return;
              }
              final app = context.read<OptiFlowController>();
              final id = 'local-${app.staffPatients.length + 1}';
              app.addStaffPatient(name: name.text, phone: phone.text, rut: rut.text, reason: reasons[reason].$2);
              showAppMessage(context, 'Paciente registrado');
              context.push('/s/patient/$id');
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text('Cancelar', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.staffAccent)),
            ),
          ),
        ],
      ),
    );
  }
}

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  static const times = ['09:00', '10:30', '12:00', '14:30', '16:00', '17:00'];
  int time = 1;

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(title: 'Nueva cita', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const IconTile(icon: Icons.calendar_today_outlined, background: AppColors.white, color: AppColors.staffHeader, size: 36, iconSize: 18),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AGENDAMIENTO · PASO ÚNICO', style: GoogleFonts.inter(fontSize: 11, color: AppColors.skyTint, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('Datos de la cita', style: GoogleFonts.inter(fontSize: 18, color: AppColors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _Label('Nombre del paciente', hint: 'Paciente registrado'),
          const SizedBox(height: 8),
          _SelectRow('Valentina Silva Morales', leading: 'VS', onTap: () => context.push('/s/patients')),
          const SizedBox(height: 18),
          const _Label('Servicio', hint: '45 min aprox.'),
          const SizedBox(height: 8),
          const _SelectRow('Examen de vista completo', icon: Icons.remove_red_eye_outlined),
          const SizedBox(height: 18),
          const _Label('Óptica / sucursal', hint: 'Disponible'),
          const SizedBox(height: 8),
          const _SelectRow('Sucursal Centro · Av. Libertad 450', icon: Icons.location_on_outlined),
          const SizedBox(height: 18),
          const _Label('Fecha', hint: 'Junio 2025'),
          const SizedBox(height: 8),
          const _SelectRow('Miércoles, 20 de junio', icon: Icons.calendar_today_outlined),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Text('Hora', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
              Text('Selecciona horario', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
            ],
          ),
          const SizedBox(height: 12),
          for (var row = 0; row < 2; row++) ...[
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 10),
                  Expanded(child: _TimeChip(times[row * 3 + col], time == row * 3 + col, () => setState(() => time = row * 3 + col))),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          SolidButton(
            label: 'Confirmar cita',
            icon: Icons.check,
            onPressed: () {
              showAppMessage(context, 'Cita agendada para las ${times[time]}');
              context.go('/s/agenda');
            },
          ),
        ],
      ),
    );
  }
}

class ClinicalCareScreen extends StatefulWidget {
  const ClinicalCareScreen({super.key});

  @override
  State<ClinicalCareScreen> createState() => _ClinicalCareScreenState();
}

class _ClinicalCareScreenState extends State<ClinicalCareScreen> {
  final note = TextEditingController();
  static const stages = [
    _CareStage(Icons.check, 'En sala de espera', 'Llegada registrada a las 10:18'),
    _CareStage(Icons.work_outline, 'En consulta optométrica', 'Anamnesis y biomicroscopía'),
    _CareStage(Icons.remove_red_eye_outlined, 'Pruebas de graduación', 'Refracción y test cromático'),
    _CareStage(Icons.grid_view, 'Elección de armazón y cristales', 'Asesoría y medidas pupilares'),
    _CareStage(Icons.settings_outlined, 'Derivado a taller / laboratorio', 'Biselado, corte y montaje'),
    _CareStage(Icons.description_outlined, 'Atención finalizada', 'Receta y comprobante clínico'),
  ];

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<OptiFlowController>().clinicalStage.clamp(0, stages.length - 1);
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(title: 'Atención clínica', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.white, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Atención en curso', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white))),
                    Text('Box 3 · Dra. Ramos', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                      child: Text('VS', style: GoogleFonts.inter(fontSize: 12, color: AppColors.electric)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Valentina Silva Morales', style: GoogleFonts.inter(fontSize: 14, color: AppColors.white)),
                        Text('Ficha #OPT-2024-849 · 10:30', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, color: AppColors.white, size: 14),
                    const SizedBox(width: 8),
                    Text('Evaluación visual completa · Turno #04', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Actualizar estado de la consulta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
              Text('Paso ${current + 1} de 6', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Selecciona la etapa actual para sincronizar recepción y taller.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
          const SizedBox(height: 12),
          for (var index = 0; index < stages.length; index++) ...[
            _StageRow(
              stages[index],
              done: index < current,
              active: index == current,
              onTap: () => context.read<OptiFlowController>().setClinicalStage(index),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          const _Label('Nota de transición', hint: 'Opcional'),
          const SizedBox(height: 8),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: _field('Añade una observación para la siguiente etapa...', Icons.notes_outlined),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const IconTile(icon: Icons.notifications_none, background: AppColors.lavender, color: AppColors.staffInk, size: 34, iconSize: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sincronización en tiempo real', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                      Text('El cambio se notificará a recepción y a la pantalla de sala.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SolidButton(
            label: 'Guardar y continuar atención',
            icon: Icons.check,
            onPressed: () {
              context.read<OptiFlowController>().setClinicalStage((current + 1).clamp(0, stages.length - 1));
              context.push('/s/evaluation');
            },
          ),
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
    final orders = context.watch<OptiFlowController>().productionOrders;
    final visible = orders.where((order) => order.stage == stage).toList();
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Producción', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in ProductionStage.values) ...[
                  _StageChip(
                    count: orders.where((order) => order.stage == item).length,
                    label: item.label,
                    selected: item == stage,
                    muted: item == ProductionStage.pending && item != stage,
                    onTap: () => setState(() => stage = item),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('${stage.label} · ${visible.length}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 14),
          if (visible.isEmpty) Text('No hay órdenes en esta etapa.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate400)),
          for (final order in visible) ...[
            _OrderCard(order, stage.label),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CareStage {
  const _CareStage(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip(this.icon, this.label, this.selected, this.onTap);
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.staffAccent : const Color(0xFFF1F5FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.white : AppColors.staffInk),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: selected ? AppColors.white : AppColors.staffInk))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow(this.label, {this.icon, this.leading, this.onTap});
  final String label;
  final IconData? icon;
  final String? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lavender)),
          child: Row(
            children: [
              if (leading != null)
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                  child: Text(leading!, style: GoogleFonts.inter(fontSize: 10, color: AppColors.electric)),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: AppColors.staffAccent),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk))),
              const Icon(Icons.expand_more, color: AppColors.staffInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.staffAccent : AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.staffAccent : AppColors.staffBorder),
          ),
          child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: selected ? AppColors.white : AppColors.staffInk)),
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow(this.stage, {required this.done, required this.active, required this.onTap});
  final _CareStage stage;
  final bool done;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFF0F4FF) : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.staffAccent : Colors.transparent, width: active ? 1.5 : 0),
          ),
          child: Row(
            children: [
              IconTile(icon: stage.icon, background: active ? const Color(0xFF0013C1) : const Color(0xFFF4F5FF), color: active ? AppColors.white : AppColors.staffAccent, size: 34, iconSize: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stage.title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk, decoration: done ? TextDecoration.lineThrough : null)),
                    Text(stage.subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
                  ],
                ),
              ),
              if (done) const Icon(Icons.check, size: 16, color: AppColors.staffInk),
              if (active) ...[
                const Icon(Icons.check, size: 12, color: AppColors.staffAccent),
                const SizedBox(width: 4),
                Text('En proceso', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.count, required this.label, required this.selected, required this.muted, required this.onTap});
  final int count;
  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF1E3D79) : (muted ? const Color(0xFFAAB6DD) : AppColors.white);
    final fg = selected ? AppColors.white : AppColors.staffHeader;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 94,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF1E3D79) : AppColors.lavender),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: GoogleFonts.inter(fontSize: 13, color: fg)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9, color: selected ? AppColors.white : AppColors.staffInk)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order, this.stageLabel);
  final ProductionOrder order;
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(order.needsAttention ? Icons.notifications_none : Icons.schedule, size: 12, color: AppColors.staffAccent),
                    const SizedBox(width: 4),
                    Text(order.needsAttention ? 'Requiere atención' : stageLabel, style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
                  ],
                ),
              ),
              const Spacer(),
              Text(order.code, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
            ],
          ),
          const SizedBox(height: 12),
          Text(order.patient, style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk)),
          const SizedBox(height: 4),
          Text(order.detail, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.staffAccent),
              const SizedBox(width: 8),
              Text(order.due, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.hint});
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
        if (hint != null) ...[
          const Spacer(),
          Text(hint!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
        ],
      ],
    );
  }
}

InputDecoration _field(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18, color: AppColors.staffInk),
    filled: true,
    fillColor: AppColors.staffField,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lavender)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lavender)),
  );
}
