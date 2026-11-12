import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/store_time.dart';
import '../../widgets/chrome.dart';

class StaffPatientRecordScreen extends StatefulWidget {
  const StaffPatientRecordScreen({super.key, required this.id});
  final String id;
  @override
  State<StaffPatientRecordScreen> createState() => _StaffPatientRecordScreenState();
}

class _StaffPatientRecordScreenState extends State<StaffPatientRecordScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) context.read<OptiFlowController>().loadStaffRecord(widget.id); });
  }

  String _diopters(num? value) {
    final number = value ?? 0;
    return '${number > 0 ? '+' : ''}${number.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final id = widget.id;
    final patient = app.staffPatient(id);
    final loading = app.staffRecordLoading.contains(id);
    final errors = app.staffRecordSectionErrors[id] ?? {};
    final records = app.staffRecordClinical[id] ?? [];
    final examined = records.where((r) => r.status != 'PENDING' && r.examinationDate != null).toList()..sort((a, b) => b.examinationDate!.compareTo(a.examinationDate!));
    final prescriptions = records.where((r) => r.prescription != null).toList()..sort((a, b) => (b.examinationDate ?? DateTime.utc(1970)).compareTo(a.examinationDate ?? DateTime.utc(1970)));
    final last = prescriptions.firstOrNull;
    final rx = last?.prescription;
    final next = (app.staffRecordAppointments[id] ?? []).where((a) => const {'CONFIRMED', 'PENDING'}.contains(a.status) && a.end.isAfter(DateTime.now())).toList()..sort((a, b) => a.start.compareTo(b.start));
    final appointment = next.firstOrNull;
    final orders = [...?app.staffRecordOrders[id]]..sort((a, b) => (b.createdAt ?? DateTime.utc(1970)).compareTo(a.createdAt ?? DateTime.utc(1970)));
    final order = orders.where((o) => o.status != 'DELIVERED').firstOrNull ?? orders.firstOrNull;
    final lastVisit = examined.isEmpty ? 'Sin visitas' : DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(examined.first.examinationDate!));
    return StaffScaffold(
      tab: null, showBottomBar: false,
      topBar: StaffTopBar(title: 'Ficha del Paciente', onBack: () => context.canPop() ? context.pop() : context.go('/s/patients')),
      body: RefreshIndicator(onRefresh: () => app.loadStaffRecord(id), child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
        if (loading) const LinearProgressIndicator(),
        if (app.staffRecordErrors[id] != null) ...[
          Text(app.staffRecordErrors[id]!, style: const TextStyle(color: AppColors.errorRed)),
          TextButton(onPressed: () => app.loadStaffRecord(id), child: const Text('Reintentar')),
        ],
        if (patient != null) ...[
          Container(padding: const EdgeInsets.fromLTRB(16, 18, 16, 18), decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 30, backgroundColor: AppColors.lavender, child: Text(patient.initials)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Paciente activo', style: TextStyle(color: Color(0xFFA7F3D0))),
                const SizedBox(height: 4), Text(patient.fullName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
                Text('ID #${patient.ficha}', style: const TextStyle(fontSize: 10, color: AppColors.slate300)),
              ])),
            ]),
            const SizedBox(height: 22),
            Row(children: [Expanded(child: _HeroFact('TELÉFONO', patient.phone)), Expanded(child: _HeroFact('ÚLTIMA VISITA', lastVisit))]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: SolidButton(label: 'Llamar', icon: Icons.phone_outlined, background: AppColors.white, foreground: AppColors.electric, onPressed: () {})),
              const SizedBox(width: 10), Expanded(child: SolidButton(label: 'Mensaje', icon: Icons.mail_outline, background: AppColors.white, foreground: AppColors.electric, onPressed: () {})),
            ]),
          ])),
          const SizedBox(height: 24), const SectionHeader('Última prescripción'), const SizedBox(height: 12),
          if (errors['clinical'] != null) Text(errors['clinical']!, style: const TextStyle(color: AppColors.errorRed))
          else if (rx == null) AppCard(child: Text(loading ? 'Cargando…' : 'Aún no tiene recetas registradas.'))
          else AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Última Prescripción', style: GoogleFonts.inter(fontSize: 18, color: AppColors.staffInk)),
            Text(last?.examinationDate == null ? 'Sin fecha' : DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(last!.examinationDate!))),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _EyeBox('Ojo derecho', '${_diopters(rx.sphereOd)} / ${_diopters(rx.cylinderOd)}', 'Eje ${rx.axisOd ?? 0}°')),
              const SizedBox(width: 8), Expanded(child: _EyeBox('Ojo izquierdo', '${_diopters(rx.sphereOs)} / ${_diopters(rx.cylinderOs)}', 'Eje ${rx.axisOs ?? 0}°')),
            ]),
            if (rx.addition != null) Text('Adición ${_diopters(rx.addition)}'),
            if (rx.treatment?.isNotEmpty == true) Text(rx.treatment!),
            if (rx.recommendedFrameType?.isNotEmpty == true) Text('Montura: ${rx.recommendedFrameType}'),
          ])),
          const SizedBox(height: 24), const SectionHeader('Próxima cita'), const SizedBox(height: 12),
          if (errors['appointments'] != null) Text(errors['appointments']!, style: const TextStyle(color: AppColors.errorRed))
          else if (appointment == null) AppCard(child: Text(loading ? 'Cargando…' : 'No tiene citas próximas.'))
          else AppCard(child: Row(children: [
            DateBadge(day: '${StoreTime.clock(appointment.start).day}', month: DateFormat('MMM', 'es').format(StoreTime.clock(appointment.start)).toUpperCase()),
            const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Pill(appointment.status == 'PENDING' ? 'Pendiente' : 'Confirmada'),
              const SizedBox(height: 4), Text('${DateFormat('HH:mm').format(StoreTime.clock(appointment.start))} · Evaluación visual'),
            ])),
          ])),
          const SizedBox(height: 24), const SectionHeader('Proceso de sus lentes'), const SizedBox(height: 12),
          if (errors['orders'] != null) Text(errors['orders']!, style: const TextStyle(color: AppColors.errorRed))
          else if (order == null) AppCard(child: Text(loading ? 'Cargando…' : 'No tiene órdenes de trabajo registradas.'))
          else AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Orden OT-${order.id.substring(0, order.id.length < 4 ? order.id.length : 4).toUpperCase()}'),
            _Pill(order.label), const SizedBox(height: 8), Text(order.detail),
            const SizedBox(height: 14), Row(children: [for (var i = 0; i < 5; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: _Progress(i <= order.step ? AppColors.staffAccent : AppColors.staffChip)))]),
            const SizedBox(height: 8), Text(order.status == 'DELIVERED' ? 'Entregada' : 'Entrega estimada: ${order.dueDate ?? 'sin fecha'}${order.delayed ? ' (atrasada)' : ''}'),
          ])),
          const SizedBox(height: 18),
          SolidButton(label: 'Nueva cita', icon: Icons.calendar_today_outlined, onPressed: () => context.push(Uri(path: '/s/appointments/new', queryParameters: {'patientId': id}).toString())),
          if (errors.isNotEmpty) TextButton(onPressed: () => app.loadStaffRecord(id), child: const Text('Volver a cargar la ficha')),
        ],
      ])),
    );
  }
}
class _HeroFact extends StatelessWidget {
  const _HeroFact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8, color: AppColors.slate300)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 15, color: AppColors.white)),
      ],
    );
  }
}

class _EyeBox extends StatelessWidget {
  const _EyeBox(this.label, this.value, this.detail);
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 17, color: AppColors.staffInk)),
          const SizedBox(height: 4),
          Text(detail, style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffAccent)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.staffBlue50, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)));
  }
}
