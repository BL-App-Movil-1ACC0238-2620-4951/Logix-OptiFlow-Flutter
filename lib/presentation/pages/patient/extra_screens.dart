import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../models/ui_models.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final sections = _sections(app.notifications);
    return PatientScaffold(
      tab: PatientTab.home,
      topBar: DarkTopBar(title: 'Notificaciones', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: app.markNotificationsRead,
              child: Text('Marcar leídas', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
            ),
          ),
          for (final section in sections) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(section.$1, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
            ),
            const SizedBox(height: 8),
            for (final item in section.$2) _NotificationRow(item, app.readNotificationIds.contains(item.id)),
          ],
        ],
      ),
    );
  }

  List<(String, List<NotificationItem>)> _sections(List<NotificationItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = {'Hoy': <NotificationItem>[], 'Ayer': <NotificationItem>[], 'Anteriores': <NotificationItem>[]};
    for (final item in items) {
      final day = DateTime(item.occurredAt.year, item.occurredAt.month, item.occurredAt.day);
      if (day == today) {
        groups['Hoy']!.add(item);
      } else if (day == yesterday) {
        groups['Ayer']!.add(item);
      } else {
        groups['Anteriores']!.add(item);
      }
    }
    return [
      for (final entry in groups.entries)
        if (entry.value.isNotEmpty) (entry.key, entry.value),
    ];
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow(this.item, this.read);
  final NotificationItem item;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      NotificationType.appointment => Icons.calendar_month_outlined,
      NotificationType.order => Icons.inventory_2_outlined,
      NotificationType.health => Icons.remove_red_eye_outlined,
      NotificationType.promo => Icons.campaign_outlined,
    };
    return Column(
      children: [
        InkWell(
          onTap: () {
            context.read<OptiFlowController>().markNotificationRead(item.id);
            final path = switch (item.type) {
              NotificationType.appointment => '/p/appointments',
              NotificationType.order => '/p/orders',
              NotificationType.health => '/p/history',
              NotificationType.promo => '/p/catalog',
            };
            context.push(path);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: icon, background: AppColors.periwinkle, color: AppColors.navyBlue, size: 40, iconSize: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: read ? FontWeight.w500 : FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 3),
                      Text(item.message, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(height: 6),
                      Text(_ago(item.occurredAt), style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
                    ],
                  ),
                ),
                if (!read)
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle))
                else if (item.navigable)
                  const Padding(padding: EdgeInsets.only(top: 18), child: Icon(Icons.chevron_right, color: AppColors.navyBlue, size: 20)),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.skyTint),
      ],
    );
  }

  String _ago(DateTime time) {
    final hours = DateTime.now().difference(time).inHours;
    if (hours < 1) return 'Hace un momento';
    if (hours < 24) return 'Hace $hours h';
    return DateFormat("d MMM", 'es').format(time);
  }
}

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key, required this.editable});
  final bool editable;

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  late final List<TextEditingController> values;
  late final TextEditingController pd;
  late final TextEditingController notes;
  late final List<TextEditingController> measures;

  @override
  void initState() {
    super.initState();
    final rx = context.read<OptiFlowController>().prescription;
    final source = widget.editable
        ? List.filled(8, '')
        : [rx.sphereOd, rx.cylinderOd, rx.axisOd, rx.additionOd, rx.sphereOi, rx.cylinderOi, rx.axisOi, rx.additionOi];
    values = [for (final text in source) TextEditingController(text: text)];
    pd = TextEditingController(text: widget.editable ? '' : rx.pupillaryDistance);
    notes = TextEditingController(text: widget.editable ? '' : rx.observations);
    measures = [for (final text in widget.editable ? List.filled(4, '') : const ['52', '18', '140', '32']) TextEditingController(text: text)];
  }

  @override
  void dispose() {
    for (final controller in [...values, pd, notes, ...measures]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rx = context.watch<OptiFlowController>().prescription;
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: DarkTopBar(title: 'Receta óptica', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF0F766E), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu receta está vigente', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text('${rx.issuedLabel} · vence en 5 meses', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
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
                            Text('Paciente', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                            Text(rx.patientName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Fecha', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                          Text(rx.date, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _RxTable(values: values, editable: widget.editable),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFE7EEFC), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.deepNavy),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Distancia pupilar (DP)', style: GoogleFonts.inter(fontSize: 13, color: AppColors.deepNavy))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          widget.editable
                              ? SizedBox(width: 72, child: TextField(controller: pd, textAlign: TextAlign.end, decoration: const InputDecoration(isDense: true, hintText: '0', border: InputBorder.none)))
                              : Text('${pd.text} mm', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          Text('31 / 31 mm', style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _Caption('DIAGNÓSTICOS ASOCIADOS'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final diagnosis in rx.diagnoses) _Chip(diagnosis),
                    if (widget.editable)
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(color: const Color(0xFFDCE6FB), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.add, size: 16, color: AppColors.electric),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEEF2F7)),
                const SizedBox(height: 10),
                const _Caption('MEDIDAS DE LA MONTURA'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Column(
                          children: [
                            Icon([Icons.crop_square, Icons.architecture, Icons.straighten, Icons.height][i], size: 18, color: AppColors.navyBlue),
                            const SizedBox(height: 6),
                            widget.editable
                                ? SizedBox(width: 44, child: TextField(controller: measures[i], textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, hintText: '0', border: InputBorder.none)))
                                : Text(measures[i].text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            Text(['Calibre', 'Puente', 'Patillas', 'Alto'][i], style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEF2F7)),
                const SizedBox(height: 10),
                const _Caption('OBSERVACIONES E INDICACIÓN'),
                const SizedBox(height: 8),
                widget.editable
                    ? TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(hintText: 'Escriba observación', border: InputBorder.none))
                    : Text(notes.text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151), height: 1.45)),
                const SizedBox(height: 14),
                const _Dash(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dra. Fernanda Soto', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                          Text('Oftalmología · Reg. 18452', style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(width: 80, height: 1, color: const Color(0xFF111827)),
                        const SizedBox(height: 4),
                        Text('Firma profesional', style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate400)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.slate500),
              const SizedBox(width: 8),
              Text('Tus datos de salud se almacenan de forma segura.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.editable)
            SolidButton(
              label: 'Guardar',
              onPressed: () {
                String axis(String raw) {
                  final text = raw.trim().isEmpty ? '0' : raw.trim();
                  return text.endsWith('°') ? text : '$text°';
                }

                String number(String raw) => raw.trim().isEmpty ? '0.00' : raw.trim();
                context.read<OptiFlowController>().savePrescription(rx.copyWith(
                      sphereOd: number(values[0].text),
                      cylinderOd: number(values[1].text),
                      axisOd: axis(values[2].text),
                      additionOd: number(values[3].text),
                      sphereOi: number(values[4].text),
                      cylinderOi: number(values[5].text),
                      axisOi: axis(values[6].text),
                      additionOi: number(values[7].text),
                      pupillaryDistance: pd.text.trim().isEmpty ? '0' : pd.text.trim(),
                      observations: notes.text,
                    ));
                showAppMessage(context, 'Receta actualizada');
                context.pop();
              },
            )
          else
            SolidButton(
              label: 'Actualizar receta',
              icon: Icons.refresh,
              background: AppColors.white,
              foreground: AppColors.electric,
              border: AppColors.skyTint,
              onPressed: () => context.push('/p/prescription/edit'),
            ),
        ],
      ),
    );
  }
}

class _RxTable extends StatelessWidget {
  const _RxTable({required this.values, required this.editable});
  final List<TextEditingController> values;
  final bool editable;

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
                        Text(header.$1, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                        if (header.$2.isNotEmpty) Text(header.$2, style: GoogleFonts.inter(fontSize: 8, color: AppColors.slate400)),
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
                        Text(row == 0 ? 'R (OD)' : 'L (OI)', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                        Text(row == 0 ? 'Derecho' : 'Izquierdo', style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                ),
                for (var col = 0; col < 3; col++)
                  Expanded(flex: col == 2 ? 8 : 10, child: _Cell(_Value(values[row * 4 + col], editable, col == 2 ? '0°' : '0.00'))),
                const Expanded(flex: 10, child: _Cell(Text('—', style: TextStyle(fontSize: 13, color: AppColors.slate400)))),
                Expanded(flex: 10, child: _Cell(_Value(values[row * 4 + 3], editable, '0.00'), last: true)),
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
  const _Value(this.controller, this.editable, this.hint);
  final TextEditingController controller;
  final bool editable;
  final String hint;

  @override
  Widget build(BuildContext context) {
    if (!editable) {
      return Text(controller.text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF111827)));
    }
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF111827)),
      decoration: InputDecoration(isDense: true, hintText: hint, border: InputBorder.none, contentPadding: EdgeInsets.zero),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.deepNavy, letterSpacing: 0.6));
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFDCE6FB), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.electric)),
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(size: Size(constraints.maxWidth, 1), painter: _DashPainter());
      },
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.slate300
      ..strokeWidth = 1;
    const dash = 8.0;
    const gap = 6.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
