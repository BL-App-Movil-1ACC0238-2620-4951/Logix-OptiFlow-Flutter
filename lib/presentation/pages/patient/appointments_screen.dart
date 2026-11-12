import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/models.dart';
import '../../models/ui_models.dart';
import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';
import 'booking_screen.dart';




class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OptiFlowController>().refreshAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final items = app.appointments.where((item) {
      return switch (tab) {
        0 => !item.isPast && item.status != AppointmentStatus.cancelled,
        1 => item.isPast && item.status != AppointmentStatus.cancelled,
        _ => item.status == AppointmentStatus.cancelled,
      };
    }).toList();
    final grouped = <String, List<AppointmentUi>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.monthName, () => []).add(item);
    }

    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(
        title: 'Mis citas',
        below: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              for (final entry in ['Próximas', 'Anteriores', 'Canceladas'].indexed) ...[
                if (entry.$1 > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TabChip(
                    label: entry.$2,
                    selected: tab == entry.$1,
                    onTap: () => setState(() => tab = entry.$1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => context.push('/p/book'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Reservar cita'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.skyTint,
                foregroundColor: AppColors.deepNavy,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (app.appointmentsLoading) const LinearProgressIndicator(),
          if (app.appointmentsError != null) ...[
            Text(app.appointmentsError!, style: const TextStyle(color: AppColors.errorRed)),
            TextButton(onPressed: app.refreshAppointments, child: const Text('Reintentar')),
          ],
          if (!app.appointmentsLoading && app.appointmentsError == null && items.isEmpty)
            Text(
              switch (tab) {
                0 => 'No tienes citas próximas.',
                1 => 'Aún no tienes citas anteriores.',
                _ => 'No tienes citas canceladas.',
              },
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
            ),
          for (final entry in grouped.entries) ...[
            Text(entry.key, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
            const SizedBox(height: 12),
            for (final item in entry.value) ...[
              _AppointmentTile(item: item),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.skyTint : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 38,
          child: Center(
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          ),
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.item});
  final AppointmentUi item;

  @override
  Widget build(BuildContext context) {
    final cancelled = item.status == AppointmentStatus.cancelled;
    return AppCard(
      onTap: () => context.push('/p/appointment/${item.id}'),
      child: Row(
        children: [
          DateBadge(day: item.day, month: item.month),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusCapsule(
                  item.status.label,
                  color: cancelled ? AppColors.errorRed : AppColors.deepNavy,
                  background: cancelled ? AppColors.errorBg : AppColors.white,
                ),
                const SizedBox(height: 4),
                Text(item.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text('${item.storeName} · ${item.time}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.slate500),
        ],
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final item = app.appointmentById(id);
    if (item == null) {
      return PatientScaffold(
        tab: PatientTab.appointments,
        topBar: DarkTopBar(title: 'Cita', onBack: () => context.go('/p/appointments')),
        body: Center(child: app.appointmentsLoading
          ? const CircularProgressIndicator()
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Text(app.appointmentsError ?? 'No encontramos esta cita.'),
              TextButton(onPressed: app.refreshAppointments, child: const Text('Volver a cargar')),
            ])),
      );
    }
    final cancelled = item.status == AppointmentStatus.cancelled;
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(title: 'Detalle de cita', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDFE7FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC3D3F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusCapsule(item.status.label, color: AppColors.deepNavy, background: AppColors.white),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DateBadge(day: item.day, month: item.month),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          Text('${item.weekday} · ${item.time} a ${item.endTime}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: [
                _DetailLine(icon: Icons.place_outlined, label: 'Ubicación', value: item.storeName, extra: item.storeAddress),
                const Divider(height: 28, color: AppColors.lavender),
                _DetailLine(icon: Icons.person_outline, label: 'Profesional', value: item.professional),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBanner,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC3D3F5)),
            ),
            child: Row(
              children: [
                const IconTile(icon: Icons.notifications_none, background: Color(0xFFC7D5F7), color: AppColors.electric),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recordatorio activado', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text('Te avisaremos 24 horas antes.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!cancelled && !item.isPast) ...[
            const SizedBox(height: 18),
            SolidButton(
              label: 'Reprogramar cita',
              icon: Icons.edit_outlined,
              background: AppColors.white,
              foreground: AppColors.electric,
              border: AppColors.skyTint,
              onPressed: app.appointmentActionLoading ? null : () => context.push('/p/reschedule/${item.id}'),
            ),
            TextButton(
              onPressed: app.appointmentActionLoading ? null : () async {
                final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
                  title: const Text('¿Cancelar esta cita?'),
                  content: Text('Se liberará tu horario del ${item.day} de ${item.monthName} a las ${item.time}.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Conservar cita')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Cancelar cita')),
                  ],
                ));
                if (accepted != true || !context.mounted) return;
                final cancelled = await app.cancelAppointment(item.id);
                if (!context.mounted) return;
                showAppMessage(context, cancelled ? 'Cita cancelada' : app.appointmentActionError ?? 'No se pudo cancelar la cita.');
              },
              child: Text(app.appointmentActionLoading ? 'Cancelando…' : 'Cancelar cita', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.electric)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label, required this.value, this.extra});
  final IconData icon;
  final String label;
  final String value;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.electric, size: 18),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              if (extra != null && extra!.isNotEmpty) Text(extra!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
            ],
          ),
        ),
      ],
    );
  }
}

class RescheduleScreen extends StatelessWidget {
  const RescheduleScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => BookingScreen(rescheduleId: id);
}
