import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ui_models.dart';
import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OptiFlowController>().markNotificationsRead());
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<OptiFlowController>().notifications;
    return PatientScaffold(
      tab: PatientTab.home,
      topBar: DarkTopBar(title: 'Notificaciones', onBack: () => context.pop()),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          final icon = switch (item.type) {
            NotificationType.appointment => Icons.calendar_month_outlined,
            NotificationType.order => Icons.inventory_2_outlined,
            NotificationType.health => Icons.favorite_border,
            NotificationType.promo => Icons.local_offer_outlined,
          };
          return AppCard(
            onTap: item.navigable ? () => context.push('/p/catalog') : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text(item.message, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600)),
                      const SizedBox(height: 4),
                      Text(_ago(item.occurredAt), style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _ago(DateTime time) {
    final delta = DateTime.now().difference(time);
    if (delta.inMinutes < 60) return 'Hace ${delta.inMinutes.clamp(1, 59)} min';
    if (delta.inHours < 24) return 'Hace ${delta.inHours} h';
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
  late final Map<String, TextEditingController> _fields;

  @override
  void initState() {
    super.initState();
    final rx = context.read<OptiFlowController>().prescription;
    _fields = {
      'sphereOd': TextEditingController(text: rx.sphereOd),
      'cylinderOd': TextEditingController(text: rx.cylinderOd),
      'axisOd': TextEditingController(text: rx.axisOd),
      'additionOd': TextEditingController(text: rx.additionOd),
      'sphereOi': TextEditingController(text: rx.sphereOi),
      'cylinderOi': TextEditingController(text: rx.cylinderOi),
      'axisOi': TextEditingController(text: rx.axisOi),
      'additionOi': TextEditingController(text: rx.additionOi),
      'pd': TextEditingController(text: rx.pupillaryDistance),
      'notes': TextEditingController(text: rx.observations),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rx = context.watch<OptiFlowController>().prescription;
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: DarkTopBar(
        title: widget.editable ? 'Editar receta' : 'Mi receta',
        onBack: () => context.pop(),
        trailing: widget.editable
            ? null
            : IconButton(onPressed: () => context.push('/p/prescription/edit'), icon: const Icon(Icons.edit_outlined, color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu receta está vigente', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text('${rx.issuedLabel} · vence en 5 meses', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paciente', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                Text(rx.patientName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text(rx.date, style: GoogleFonts.inter(color: AppColors.slate500)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [for (final d in rx.diagnoses) Chip(label: Text(d))]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EyeTable(title: 'Ojo derecho (OD)', editable: widget.editable, fields: _fields, keys: const ['sphereOd', 'cylinderOd', 'axisOd', 'additionOd'], labels: const ['Esfera', 'Cilindro', 'Eje', 'Adición'], values: [rx.sphereOd, rx.cylinderOd, rx.axisOd, rx.additionOd]),
          const SizedBox(height: 12),
          _EyeTable(title: 'Ojo izquierdo (OI)', editable: widget.editable, fields: _fields, keys: const ['sphereOi', 'cylinderOi', 'axisOi', 'additionOi'], labels: const ['Esfera', 'Cilindro', 'Eje', 'Adición'], values: [rx.sphereOi, rx.cylinderOi, rx.axisOi, rx.additionOi]),
          const SizedBox(height: 12),
          AppCard(
            child: widget.editable
                ? TextField(controller: _fields['notes'], maxLines: 3, decoration: const InputDecoration(labelText: 'Observaciones'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Observaciones', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 6),
                      Text(rx.observations, style: GoogleFonts.inter(color: AppColors.slate600)),
                      const SizedBox(height: 8),
                      Text('Distancia pupilar ${rx.pupillaryDistance} mm', style: GoogleFonts.inter(color: AppColors.slate500)),
                    ],
                  ),
          ),
          if (widget.editable) ...[
            const SizedBox(height: 16),
            SolidButton(
              label: 'Guardar receta',
              onPressed: () {
                final app = context.read<OptiFlowController>();
                app.savePrescription(rx.copyWith(
                  sphereOd: _fields['sphereOd']!.text,
                  cylinderOd: _fields['cylinderOd']!.text,
                  axisOd: _fields['axisOd']!.text,
                  additionOd: _fields['additionOd']!.text,
                  sphereOi: _fields['sphereOi']!.text,
                  cylinderOi: _fields['cylinderOi']!.text,
                  axisOi: _fields['axisOi']!.text,
                  additionOi: _fields['additionOi']!.text,
                  pupillaryDistance: _fields['pd']!.text,
                  observations: _fields['notes']!.text,
                ));
                showAppMessage(context, 'Receta actualizada en este dispositivo.');
                context.pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _EyeTable extends StatelessWidget {
  const _EyeTable({required this.title, required this.editable, required this.fields, required this.keys, required this.labels, required this.values});

  final String title;
  final bool editable;
  final Map<String, TextEditingController> fields;
  final List<String> keys;
  final List<String> labels;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: editable
                      ? TextField(controller: fields[keys[i]], decoration: InputDecoration(labelText: labels[i], isDense: true))
                      : Column(
                          children: [
                            Text(labels[i], style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                            Text(values[i], style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          ],
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
