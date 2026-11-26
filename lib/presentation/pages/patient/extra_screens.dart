import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    return ListenableBuilder(
      listenable: patientVm,
      builder: (context, _) {
        final rx = patientVm.state.prescription;
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: DarkTopBar(title: 'Receta óptica', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (rx == null && patientVm.state.patientLoading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (rx == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.description_outlined, size: 40, color: AppColors.slate400),
                      const SizedBox(height: 12),
                      Text('Aún no tienes recetas', style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 6),
                      Text('Tu receta aparecerá aquí después de tu evaluación visual.', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 13, color: AppColors.slate500)),
                    ],
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.infoBanner, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.skyTint)),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_outlined, color: Color(0xFF0F766E), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tu última receta', style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            Text(rx.issuedLabel, style: AppFonts.inter(fontSize: 13, color: AppColors.slate500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF4F6FD), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Paciente', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                                  Text(rx.patientName, style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Fecha', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                                Text(rx.date, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _RxTable(values: [rx.sphereOd, rx.cylinderOd, rx.axisOd, rx.additionOd, rx.sphereOi, rx.cylinderOi, rx.axisOi, rx.additionOi]),
                      ),
                      if (rx.observations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const _Caption('OBSERVACIONES E INDICACIÓN'),
                        const SizedBox(height: 8),
                        Text(rx.observations, style: AppFonts.inter(fontSize: 13, color: const Color(0xFF374151), height: 1.45)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.slate500),
                    const SizedBox(width: 8),
                    Text('Tus datos de salud se almacenan de forma segura.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RxTable extends StatelessWidget {
  const _RxTable({required this.values});
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    const headers = [('Ojo', ''), ('Esfera', 'SPH'), ('Cilindro', 'CYL'), ('Eje', 'AXIS'), ('Prisma', ''), ('Adición', 'ADD')];
    return Container(
      width: 560,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1))),
      child: Column(
        children: [
          Row(
            children: [
              for (final header in headers)
                Expanded(
                  flex: header.$1 == 'Ojo' ? 13 : (header.$1 == 'Eje' ? 8 : 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFCBD5E1)))),
                    child: Column(
                      children: [
                        Text(header.$1, style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                        if (header.$2.isNotEmpty) Text(header.$2, style: AppFonts.inter(fontSize: 8, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          for (var row = 0; row < 2; row++) ...[
            const Divider(height: 1, color: Color(0xFFCBD5E1)),
            Row(
              children: [
                Expanded(
                  flex: 13,
                  child: _Cell(
                    Column(
                      children: [
                        Text(row == 0 ? 'R (OD)' : 'L (OI)', style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                        Text(row == 0 ? 'Derecho' : 'Izquierdo', style: AppFonts.inter(fontSize: 9, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                ),
                for (var col = 0; col < 3; col++)
                  Expanded(flex: col == 2 ? 8 : 10, child: _Cell(_Value(values[row * 4 + col]))),
                const Expanded(flex: 10, child: _Cell(Text('—', style: TextStyle(fontSize: 13, color: AppColors.slate400)))),
                Expanded(flex: 10, child: _Cell(_Value(values[row * 4 + 3]), last: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.child, {this.last = false});
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: last ? null : const Border(right: BorderSide(color: Color(0xFFCBD5E1)))),
      child: child,
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF111827)));
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.deepNavy, letterSpacing: 0.6));
  }
}
