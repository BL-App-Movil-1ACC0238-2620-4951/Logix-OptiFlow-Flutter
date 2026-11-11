import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

/// Lista de prescripciones del paciente (obtenidas de registros clínicos).
/// Equivalente a la ruta P_PRESCRIPTIONS en Android.
class PrescriptionsListScreen extends StatelessWidget {
  const PrescriptionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final history = app.history;
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: DarkTopBar(title: 'Mis recetas', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const IconTile(icon: Icons.description_outlined, background: AppColors.emerald600, color: AppColors.white, size: 44, iconSize: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recetas disponibles', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text('${history.length} registro${history.length == 1 ? '' : 's'} clínico${history.length == 1 ? '' : 's'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Receta actual (del controller)
          AppCard(
            onTap: () => context.push('/p/prescription'),
            child: Row(
              children: [
                const IconTile(icon: Icons.visibility_outlined, size: 48, iconSize: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receta vigente', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text(app.prescription.issuedLabel, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                      Text(app.prescription.patientName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate400),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Registros clínicos', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Aún no tienes registros clínicos.', style: GoogleFonts.inter(color: AppColors.slate500)),
              ),
            ),
          for (var i = 0; i < history.length; i++) ...[
            AppCard(
              onTap: () => context.push('/p/prescriptions/$i'),
              child: Row(
                children: [
                  DateBadge(
                    day: history[i].date.length >= 2 ? history[i].date.substring(0, 2).trim() : '—',
                    month: history[i].date.length >= 6 ? history[i].date.substring(3, 6).trim().toUpperCase() : '',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history[i].title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        Text(history[i].summary, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600)),
                        Text(history[i].professional, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.slate400),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Detalle de una prescripción específica (por índice de registro clínico).
/// Equivalente a la ruta P_PRESCRIPTION_DETAIL en Android.
class PrescriptionDetailScreen extends StatelessWidget {
  const PrescriptionDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final index = int.tryParse(id);
    final history = app.history;
    final entry = (index != null && index >= 0 && index < history.length) ? history[index] : null;
    final rx = app.prescription;

    if (entry == null) {
      return PatientScaffold(
        tab: PatientTab.profile,
        topBar: DarkTopBar(title: 'Receta', onBack: () => context.pop()),
        body: const Center(child: Text('Registro no encontrado.')),
      );
    }

    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: DarkTopBar(title: entry.title, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(icon: Icons.calendar_month_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.4)),
                          Text(entry.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Profesional', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                Text(entry.professional, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 12),
                Text('Observaciones', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                Text(entry.summary, style: GoogleFonts.inter(color: AppColors.slate600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Valores de la receta asociada', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ojo derecho (OD)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final pair in [('Esfera', rx.sphereOd), ('Cilindro', rx.cylinderOd), ('Eje', rx.axisOd), ('Adición', rx.additionOd)])
                      Expanded(
                        child: Column(
                          children: [
                            Text(pair.$1, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                            Text(pair.$2, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ojo izquierdo (OI)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final pair in [('Esfera', rx.sphereOi), ('Cilindro', rx.cylinderOi), ('Eje', rx.axisOi), ('Adición', rx.additionOi)])
                      Expanded(
                        child: Column(
                          children: [
                            Text(pair.$1, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                            Text(pair.$2, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observaciones de receta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 6),
                Text(rx.observations, style: GoogleFonts.inter(color: AppColors.slate600)),
                const SizedBox(height: 8),
                Text('Distancia pupilar ${rx.pupillaryDistance} mm', style: GoogleFonts.inter(color: AppColors.slate500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [for (final d in rx.diagnoses) Chip(label: Text(d))]),
        ],
      ),
    );
  }
}
