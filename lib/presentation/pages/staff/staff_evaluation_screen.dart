import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class VisualEvaluationScreen extends StatelessWidget {
  const VisualEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.agenda,
      topBar: StaffTopBar(
        title: 'Evaluación Visual',
        subtitle: 'Óptica Visión Norte',
        onBack: () => context.pop(),
        trailing: IconButton(onPressed: () => context.push('/s/patient/vs'), icon: const Icon(Icons.person_outline, color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(color: const Color(0xFF172A46), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                      child: Text('VS', style: GoogleFonts.inter(fontSize: 11, color: AppColors.electric)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Valentina Silva', style: GoogleFonts.inter(fontSize: 14, color: AppColors.white)),
                          Text('Ficha #OPT-2024-849 · Control anual', style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate300)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('28 años', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Row(
                  children: [
                    Expanded(child: _Fact('FECHA', '20 Jun 2024')),
                    Expanded(child: _Fact('OPTOMETRISTA', 'Dr. C. Ramos')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            icon: Icons.remove_red_eye_outlined,
            title: 'Graduación y Refracción',
            trailing: 'Distancia lejos',
            child: Column(
              children: [
                const Row(children: [_Cell('OJO', header: true), _Cell('ESFERA', header: true), _Cell('CILINDRO', header: true), _Cell('EJE', header: true), _Cell('AV', header: true)]),
                const SizedBox(height: 8),
                _GradeRow(const ['OD', '-2.25', '-0.75', '85°']),
                const SizedBox(height: 8),
                _GradeRow(const ['OI', '-2.00', '-0.50', '95°']),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(child: _Measure('Distancia pupilar (DP)', '62 mm', 'Ambos ojos')),
                    SizedBox(width: 8),
                    Expanded(child: _Measure('Adición (cerca)', 'N/A', 'No aplica')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            icon: Icons.description_outlined,
            title: 'Fórmula de Cristales',
            trailing: 'Laboratorio Norte',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Monofocal Orgánico Alto Índice 1.60', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk))),
                      _Tag('Recomendado'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Tratamientos ópticos formulados para fatiga digital y trabajo frente a pantallas:', style: GoogleFonts.inter(fontSize: 9, color: AppColors.staffInk)),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag('Filtro Blue Block', outlined: true),
                      _Tag('Antirreflejo Premium', outlined: true),
                      _Tag('Hidrofóbico', outlined: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            icon: Icons.remove_red_eye_outlined,
            title: 'Armazón Seleccionado',
            trailing: 'En stock (2)',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/img_eval_frame.png', width: 72, height: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RAY-BAN', style: GoogleFonts.inter(fontSize: 7, color: AppColors.staffAccent)),
                        Text('Clubmaster Classic Carey', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                        Text('Ref: #RB5154 · Calibre 49-21', style: GoogleFonts.inter(fontSize: 7, color: AppColors.slate400)),
                        const SizedBox(height: 4),
                        Text('\$145.000 CLP', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.staffInk)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.staffBlue50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: AppColors.staffAccent, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado de la atención', style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffInk)),
                      Text('Listo para generar orden al taller', style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffInk)),
                    ],
                  ),
                ),
                const Icon(Icons.check, color: AppColors.staffInk, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SolidButton(label: 'Confirmar y enviar a laboratorio', icon: Icons.chevron_right, onPressed: () => context.push('/s/work-order')),
          const SizedBox(height: 10),
          SolidButton(
            label: 'Enviar receta por WhatsApp / Email',
            icon: Icons.mail_outline,
            background: AppColors.white,
            foreground: AppColors.staffInk,
            border: AppColors.staffBorder,
            onPressed: () => showAppMessage(context, 'Receta enviada al paciente'),
          ),
        ],
      ),
    );
  }
}

class WorkOrderScreen extends StatelessWidget {
  const WorkOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Ojo', 'Esfera', 'Cilindro', 'Eje'],
      ['OD', '-1.25', '-0.50', '175°'],
      ['OI', '-1.00', '-0.75', '10°'],
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
                Text('OT-2048 · Valentina Silva', style: GoogleFonts.inter(fontSize: 20, color: AppColors.staffInk)),
                const SizedBox(height: 6),
                Text('Venta #V-1038 · Entrega 28 de junio', style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Especificaciones', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              children: [
                _Spec(Icons.remove_red_eye_outlined, 'Montura', 'Nova N-24 · Azul · 52–18–140'),
                Divider(height: 24, color: AppColors.staffBorder),
                _Spec(Icons.description_outlined, 'Lentes', 'Monofocal 1.60 · Antirreflejo'),
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
            label: 'Crear y enviar a producción',
            onPressed: () {
              showAppMessage(context, 'Orden OT-2048 enviada a producción');
              context.go('/s/production');
            },
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate300)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppColors.white)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.trailing, required this.child});
  final IconData icon;
  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: icon, size: 32, background: const Color(0xFFEEF2FF), color: AppColors.staffAccent),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk))),
              _Tag(trailing),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false});
  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 8, color: header ? AppColors.slate400 : AppColors.staffInk)),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow(this.values);
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: const Color(0xFFF4F6FD), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(child: Text(values[i], textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: i == 0 ? AppColors.staffAccent : AppColors.staffInk))),
          const Expanded(child: Center(child: _Tag('20/20'))),
        ],
      ),
    );
  }
}

class _Measure extends StatelessWidget {
  const _Measure(this.label, this.value, this.detail);
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 7, color: AppColors.staffInk)),
                const SizedBox(height: 6),
                Text(detail, style: GoogleFonts.inter(fontSize: 7, color: AppColors.staffInk)),
              ],
            ),
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffAccent)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.outlined = false});
  final String text;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? AppColors.white : AppColors.staffBlue50,
        borderRadius: BorderRadius.circular(outlined ? 6 : 20),
        border: outlined ? Border.all(color: const Color(0xFF93C5FD)) : null,
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 8, color: outlined ? AppColors.staffAccent : AppColors.staffInk)),
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
