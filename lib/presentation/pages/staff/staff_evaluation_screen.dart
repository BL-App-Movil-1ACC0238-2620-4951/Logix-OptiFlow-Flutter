import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

import 'staff_clinical_care_screen.dart';

class VisualEvaluationScreen extends StatelessWidget {
  const VisualEvaluationScreen({super.key, this.patientId, this.appointmentId});
  final String? patientId;
  final String? appointmentId;
  @override
  Widget build(BuildContext context) => ClinicalCareScreen(patientId: patientId, appointmentId: appointmentId);
}

class WorkOrderScreen extends StatelessWidget {
  const WorkOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Ojo', 'Esfera', 'Cilindro', 'Eje'],
      ['OD', '-1.25', '-0.50', '175┬░'],
      ['OI', '-1.00', '-0.75', '10┬░'],
    ];
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Orden de trabajo', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFFDCE9FF), Color(0xFFF1F5FF)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tag('Lista para crear'),
                const SizedBox(height: 14),
                Text('OT-2048 ┬À Valentina Silva', style: GoogleFonts.inter(fontSize: 20, color: AppColors.staffInk)),
                const SizedBox(height: 6),
                Text('Venta #V-1038 ┬À Entrega 28 de junio', style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Especificaciones', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              children: [
                _Spec(Icons.remove_red_eye_outlined, 'Montura', 'Nova N-24 ┬À Azul ┬À 52ÔÇô18ÔÇô140'),
                Divider(height: 24, color: AppColors.staffBorder),
                _Spec(Icons.description_outlined, 'Lentes', 'Monofocal 1.60 ┬À Antirreflejo'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var row = 0; row < rows.length; row++) ...[
                  if (row > 0) const Divider(height: 1, color: AppColors.staffBorder),
                  SizedBox(
                    height: row == 0 ? 42 : 44,
                    child: Row(
                      children: [
                        for (var col = 0; col < rows[row].length; col++)
                          Expanded(
                            child: Text(
                              rows[row][col],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: row == 0 ? 9 : 11,
                                color: col == 0 && row > 0 ? AppColors.staffAccent : AppColors.staffInk,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 36),
          SolidButton(
            label: 'Crear y enviar a producci├│n',
            onPressed: () {
              showAppMessage(context, 'Orden OT-2048 enviada a producci├│n');
              context.go('/s/production');
            },
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.staffBlue50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffInk)),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.staffInk, size: 22),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
            Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          ],
        ),
      ],
    );
  }
}
