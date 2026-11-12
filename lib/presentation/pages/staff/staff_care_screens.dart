import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/store_time.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/production_order.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

export 'staff_clinical_care_screen.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});
  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final dni = TextEditingController();
  final birth = TextEditingController();
  @override
  void dispose() { name.dispose(); email.dispose(); phone.dispose(); dni.dispose(); birth.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final busy = app.staffPatientSaving;
    return StaffScaffold(
      tab: null, showBottomBar: false,
      topBar: StaffTopBar(title: 'Nuevo Cliente', onBack: () { if (!busy) { context.canPop() ? context.pop() : context.go('/s/patients'); } }),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)), child: Row(children: [
          const IconTile(icon: Icons.description_outlined, background: AppColors.white, color: AppColors.staffHeader, size: 36),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FICHA DIGITAL', style: TextStyle(color: AppColors.skyTint, fontSize: 11)),
            SizedBox(height: 6), Text('Registro rápido de paciente', style: TextStyle(color: AppColors.white, fontSize: 18)),
            SizedBox(height: 6), Text('El paciente podrá entrar a la app con su correo y su DNI como contraseña temporal.', style: TextStyle(color: AppColors.white, fontSize: 11)),
          ])),
        ])),
        const SizedBox(height: 18),
        const _Label('Nombre completo'), const SizedBox(height: 10),
        TextField(controller: name, enabled: !busy, maxLength: 80, decoration: _field('Camila Paz Morales', Icons.person_outline)),
        const SizedBox(height: 16),
        const _Label('Correo electrónico'), const SizedBox(height: 10),
        TextField(controller: email, enabled: !busy, keyboardType: TextInputType.emailAddress, decoration: _field('camila@correo.com', Icons.mail_outline)),
        const SizedBox(height: 16),
        const _Label('Teléfono móvil'), const SizedBox(height: 10),
        TextField(controller: phone, enabled: !busy, maxLength: 20, keyboardType: TextInputType.phone, decoration: _field('987 654 321', Icons.phone_outlined)),
        const SizedBox(height: 16),
        const _Label('DNI', hint: 'Será su contraseña temporal'), const SizedBox(height: 10),
        TextField(controller: dni, enabled: !busy, maxLength: 8, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number, decoration: _field('45879632', Icons.credit_card_outlined)),
        const SizedBox(height: 16),
        const _Label('Fecha de nacimiento', hint: 'Opcional · dd/mm/aaaa'), const SizedBox(height: 10),
        TextField(controller: birth, enabled: !busy, maxLength: 10, keyboardType: TextInputType.datetime, decoration: _field('24/05/1990', Icons.calendar_today_outlined)),
        if (app.staffPatientSaveError != null) Text(app.staffPatientSaveError!, style: const TextStyle(color: AppColors.errorRed)),
        const SizedBox(height: 24),
        SolidButton(label: 'Guardar paciente', loading: busy, icon: Icons.check, onPressed: () async {
          final id = await app.registerStaffPatient(name: name.text, email: email.text, phone: phone.text, dni: dni.text, birthDate: birth.text);
          if (!context.mounted || id == null) return;
          showAppMessage(context, 'Paciente registrado');
          context.replace('/s/patient/${Uri.encodeComponent(id)}');
        }),
        TextButton(onPressed: busy ? null : () => context.canPop() ? context.pop() : context.go('/s/patients'), child: const Text('Cancelar')),
      ]),
    );
  }
}

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key, this.patientId});
  final String? patientId;
  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  bool choosingPatient = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) context.read<OptiFlowController>().prepareStaffBooking(patientId: widget.patientId); });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final patient = app.staffBookingPatientId == null ? null : app.staffPatient(app.staffBookingPatientId!);
    final days = {for (final slot in app.staffBookingSlots) StoreTime.day(slot.start)}.toList();
    final slots = app.staffBookingSlots.where((slot) => app.staffBookingDay != null && StoreTime.isoDay(StoreTime.day(slot.start)) == StoreTime.isoDay(app.staffBookingDay!)).toList();
    final busy = app.staffBookingSaving;
    return StaffScaffold(
      tab: null, showBottomBar: false,
      topBar: StaffTopBar(title: 'Nueva cita', onBack: () { if (!busy) { context.canPop() ? context.pop() : context.go('/s/agenda'); } }),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)), child: const Row(children: [
          IconTile(icon: Icons.calendar_today_outlined, background: AppColors.white, color: AppColors.staffHeader, size: 36),
          SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AGENDAMIENTO · PASO ÚNICO', style: TextStyle(fontSize: 11, color: AppColors.skyTint)),
            SizedBox(height: 4), Text('Datos de la cita', style: TextStyle(fontSize: 18, color: AppColors.white)),
          ])),
        ])),
        const SizedBox(height: 18), const _Label('Paciente', hint: 'Registrado en OptiFlow'), const SizedBox(height: 8),
        _SelectRow(patient?.fullName ?? 'Elegir paciente', leading: patient?.initials, icon: patient == null ? Icons.person_outline : null, onTap: () { if (!busy) setState(() => choosingPatient = !choosingPatient); }),
        if (choosingPatient) ...[
          if (app.staffPatientsLoading) const LinearProgressIndicator(),
          if (app.staffPatientsError != null) TextButton(onPressed: app.refreshStaffPatients, child: Text(app.staffPatientsError!)),
          if (!app.staffPatientsLoading && app.staffPatients.isEmpty) const Text('Todavía no hay pacientes registrados.'),
          for (final option in app.staffPatients) ListTile(title: Text(option.fullName), subtitle: Text(option.email), onTap: busy ? null : () {
            app.selectStaffBooking(patientId: option.id); setState(() => choosingPatient = false);
          }),
        ],
        const SizedBox(height: 18), const _Label('Fecha', hint: 'Turnos libres de mi óptica'), const SizedBox(height: 12),
        if (app.staffBookingLoading) const LinearProgressIndicator()
        else if (days.isEmpty) const Text('No hay horarios libres. El administrador puede abrirlos en Más > Horarios de atención.')
        else ...[
          Wrap(spacing: 8, runSpacing: 8, children: [for (final day in days)
            SizedBox(width: 105, child: _TimeChip(DateFormat('EEE d MMM', 'es').format(day), day == app.staffBookingDay, () { if (!busy) app.selectStaffBooking(day: day); })),
          ]),
          const SizedBox(height: 18), const _Label('Hora', hint: 'Selecciona horario'), const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final slot in slots)
            SizedBox(width: 96, child: _TimeChip(DateFormat('HH:mm').format(StoreTime.clock(slot.start)), slot.id == app.staffBookingSlotId, () { if (!busy) app.selectStaffBooking(slotId: slot.id); })),
          ]),
        ],
        if (app.staffBookingError != null) ...[
          const SizedBox(height: 12), Text(app.staffBookingError!, style: const TextStyle(color: AppColors.errorRed)),
          TextButton(onPressed: busy ? null : app.reloadStaffBookingSlots, child: const Text('Actualizar horarios')),
        ],
        const SizedBox(height: 20),
        SolidButton(label: 'Confirmar cita', loading: busy, icon: Icons.check, onPressed: app.staffBookingLoading ? null : () async {
          final booked = await app.confirmStaffBooking();
          if (!context.mounted || !booked) return;
          showAppMessage(context, 'Cita agendada.');
          if (context.canPop()) { context.pop(); } else { context.go('/s/agenda'); }
        }),
      ]),
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
