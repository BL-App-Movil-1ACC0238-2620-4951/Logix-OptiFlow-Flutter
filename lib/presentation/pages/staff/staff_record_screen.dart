import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class StaffPatientRecordScreen extends StatelessWidget {
  const StaffPatientRecordScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<OptiFlowController>().staffPatient(id);
    return StaffScaffold(
      tab: StaffTab.patients,
      topBar: StaffTopBar(
        title: 'Ficha del Paciente',
        onBack: () => context.pop(),
        trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: AppColors.white)),
      ),
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
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(18)),
                      child: Text(patient.initials, style: GoogleFonts.inter(fontSize: 16, color: AppColors.electric)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0x3310B981), borderRadius: BorderRadius.circular(20)),
                            child: Text('Paciente activo', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA7F3D0))),
                          ),
                          const SizedBox(height: 4),
                          Text(patient.fullName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
                          Text('ID #${patient.ficha}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate300)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: _HeroFact('TELÉFONO', patient.phone)),
                    Expanded(child: _HeroFact('ÚLTIMA VISITA', patient.lastVisit)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: SolidButton(label: 'Llamar', icon: Icons.phone_outlined, background: AppColors.white, foreground: const Color(0xFF0013C1), onPressed: () => showAppMessage(context, 'Llamada a ${patient.phone}'))),
                    const SizedBox(width: 10),
                    Expanded(child: SolidButton(label: 'Mensaje', icon: Icons.mail_outline, background: AppColors.white, foreground: const Color(0xFF0013C1), onPressed: () => showAppMessage(context, 'Mensaje listo para ${patient.fullName}'))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Última prescripción', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
              GestureDetector(
                onTap: () => context.push('/s/evaluation'),
                child: Text('Ver historial', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffAccent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, color: AppColors.staffAccent, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Última Prescripción', style: GoogleFonts.inter(fontSize: 18, color: AppColors.staffInk)),
                          Text('Dr. Sergio Ramos · 24 jun 2023', style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffInk)),
                        ],
                      ),
                    ),
                    _Pill('Vigente'),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(child: _EyeBox('Ojo derecho', '-1.75 / -0.50', '180° · DP 31.5')),
                    SizedBox(width: 8),
                    Expanded(child: _EyeBox('Ojo izquierdo', '-2.00 / -0.75', '175° · DP 31.0')),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                  child: Text('Monofocal Filtro Azul 1.60', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffAccent)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Próxima cita', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.go('/s/agenda'),
            child: Row(
              children: [
                const DateBadge(day: '20', month: 'JUN'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Pill('Confirmada'),
                      const SizedBox(height: 4),
                      Text('Evaluación visual completa', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                      Text('10:30 · Control visual integral', style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.staffInk),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Proceso de sus lentes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
              GestureDetector(
                onTap: () => context.push('/s/production'),
                child: Text('Orden OT-2048', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffAccent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/s/production'),
            child: Column(
              children: [
                Row(
                  children: [
                    const IconTile(icon: Icons.settings_outlined, size: 36, background: Color(0xFFEEF2FF), color: AppColors.staffAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Pill('En taller'),
                          const SizedBox(height: 4),
                          Text('Biselado y montaje', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                          Text('Montura Ray-Ban · Cristales monofocales 1.60', style: GoogleFonts.inter(fontSize: 9, color: AppColors.staffInk)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.staffInk),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(child: _Progress(AppColors.staffAccent)),
                    SizedBox(width: 6),
                    Expanded(child: _Progress(AppColors.staffAccent)),
                    SizedBox(width: 6),
                    Expanded(child: _Progress(Color(0xFF93C5FD))),
                    SizedBox(width: 6),
                    Expanded(child: _Progress(AppColors.staffChip)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text('Pedido recibido', style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffInk))),
                    Text('Entrega estimada: 28 de junio', style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffAccent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: SolidButton(label: 'Nueva cita', icon: Icons.calendar_today_outlined, onPressed: () => context.push('/s/appointments/new'))),
              const SizedBox(width: 10),
              Expanded(
                child: SolidButton(
                  label: 'Iniciar atención',
                  icon: Icons.add,
                  background: AppColors.white,
                  foreground: AppColors.staffInk,
                  border: AppColors.staffBorder,
                  onPressed: () => context.push('/s/clinical'),
                ),
              ),
            ],
          ),
        ],
      ),
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
