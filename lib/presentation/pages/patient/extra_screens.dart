import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

const _ink = Color(0xFF111827);
const _tableBorder = Color(0xFFCBD5E1);

class _MessageScreen extends StatelessWidget {
  const _MessageScreen({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PatientScaffold(
      tab: null,
      topBar: DarkTopBar(title: 'Receta óptica', onBack: () => context.pop()),
      body: Padding(padding: const EdgeInsets.all(24), child: SizedBox(width: double.infinity, child: child)),
    );
  }
}

class _NoPrescription extends StatelessWidget {
  const _NoPrescription();

  @override
  Widget build(BuildContext context) {
    return _MessageScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aún no tienes una receta registrada.', style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
          const SizedBox(height: 8),
          Text('Aparecerá aquí después de tu evaluación visual en la óptica.', style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
        ],
      ),
    );
  }
}

class PrescriptionListScreen extends StatelessWidget {
  const PrescriptionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    return ListenableBuilder(
      listenable: patientVm,
      builder: (context, _) {
        final state = patientVm.state;
        if (!state.patientLoading && state.prescriptions.isEmpty) return const _NoPrescription();
        return PatientScaffold(
          tab: null,
          topBar: DarkTopBar(title: 'Mis recetas', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            children: [
              if (state.patientLoading) Text('Cargando tus recetas...', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
              for (final (index, item) in state.prescriptions.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    borderColor: AppColors.lavender,
                    onTap: () => context.push('/p/prescriptions/${Uri.encodeComponent(item.recordId)}'),
                    child: Row(
                      children: [
                        const IconTile(icon: LucideIcons.fileText, background: AppColors.lavender, color: AppColors.electric, size: 40, iconSize: 18, radius: 12),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(index == 0 ? 'Receta vigente' : 'Receta anterior', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                              Text('${item.date} · ${item.summary}', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.slate400),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Sin [recordId] muestra la receta más reciente; con él, la consulta al backend.
class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key, this.recordId});
  final String? recordId;

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _patientVm = getIt<PatientViewModel>();

  @override
  void initState() {
    super.initState();
    final id = widget.recordId;
    if (id != null) _patientVm.loadPrescription(id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _patientVm,
      builder: (context, _) {
        final state = _patientVm.state;
        final id = widget.recordId;
        final rx = id != null ? state.selectedPrescription : state.prescription;
        if (id != null && rx == null) {
          final error = state.selectedPrescriptionError;
          return _MessageScreen(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error ?? 'Cargando receta...', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _patientVm.loadPrescription(id),
                    child: Text('Reintentar', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.electric)),
                  ),
                ],
              ],
            ),
          );
        }
        // La receta la registra el optómetra en la óptica; el paciente solo la consulta.
        if (rx == null) {
          if (state.patientLoading) {
            return const _MessageScreen(child: Center(child: CircularProgressIndicator()));
          }
          return const _NoPrescription();
        }
        final isCurrent = id == null || state.prescriptions.firstOrNull?.recordId == id;
        return PatientScaffold(
          tab: null,
          topBar: DarkTopBar(title: 'Receta óptica', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(color: AppColors.infoBanner, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.skyTint)),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.badgeCheck, color: Color(0xFF0F766E), size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isCurrent ? 'Tu receta más reciente' : 'Receta anterior', style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          Text(rx.issuedLabel, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(radius: 24, child: _PrescriptionBody(rx)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.slate500),
                  const SizedBox(width: 8),
                  Flexible(child: Text('Tus datos de salud se almacenan de forma segura.', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrescriptionBody extends StatelessWidget {
  const _PrescriptionBody(this.rx);
  final PrescriptionUi rx;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    Text('Paciente', style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate400)),
                    Text(rx.patientName, style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Fecha', style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate400)),
                  Text(rx.date, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RxTable(values: [rx.sphereOd, rx.cylinderOd, rx.axisOd, rx.additionOd, rx.sphereOi, rx.cylinderOi, rx.axisOi, rx.additionOi]),
        const SizedBox(height: 16),
        const _Caption('OBSERVACIONES E INDICACIÓN'),
        const SizedBox(height: 8),
        Text(rx.observations.isEmpty ? 'Sin observaciones.' : rx.observations, style: AppFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF374151), height: 19 / 13)),
        const SizedBox(height: 14),
        const SizedBox(width: double.infinity, height: 1, child: CustomPaint(painter: _DashedLine())),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Optometrista de OptiFlow', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
                  Text('Receta emitida en la óptica', style: AppFonts.plusJakartaSans(fontSize: 10, color: AppColors.slate400)),
                ],
              ),
            ),
            Column(
              children: [
                Container(width: 80, height: 1, color: _ink),
                const SizedBox(height: 4),
                Text('Firma profesional', style: AppFonts.plusJakartaSans(fontSize: 9, color: AppColors.slate400)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.slate300
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset((x + 4).clamp(0, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RxTable extends StatelessWidget {
  const _RxTable({required this.values});
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    const headers = [('Ojo', '', 13), ('Esfera', 'SPH', 10), ('Cilindro', 'CYL', 10), ('Eje', 'AXIS', 8), ('Prisma', '', 10), ('Adición', 'ADD', 10)];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _tableBorder)),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, header) in headers.indexed)
                  Expanded(
                    flex: header.$3,
                    child: _Cell(
                      vertical: 10,
                      last: i == headers.length - 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(header.$1, maxLines: 1, overflow: TextOverflow.visible, softWrap: false, style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: _ink)),
                          if (header.$2.isNotEmpty) Text(header.$2, style: AppFonts.plusJakartaSans(fontSize: 8, color: AppColors.slate400)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var row = 0; row < 2; row++) ...[
            const Divider(height: 1, thickness: 1, color: _tableBorder),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 13,
                    child: _Cell(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(row == 0 ? 'R (OD)' : 'L (OI)', style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                          Text(row == 0 ? 'Derecho' : 'Izquierdo', style: AppFonts.plusJakartaSans(fontSize: 9, color: AppColors.slate400)),
                        ],
                      ),
                    ),
                  ),
                  for (var col = 0; col < 3; col++)
                    Expanded(flex: col == 2 ? 8 : 10, child: _Cell(child: _Value(values[row * 4 + col]))),
                  Expanded(flex: 10, child: _Cell(child: Text('—', style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate400)))),
                  Expanded(flex: 10, child: _Cell(last: true, child: _Value(values[row * 4 + 3]))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.last = false, this.vertical = 14});
  final Widget child;
  final bool last;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: vertical, horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: last ? null : const Border(right: BorderSide(color: _tableBorder))),
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: _ink));
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
