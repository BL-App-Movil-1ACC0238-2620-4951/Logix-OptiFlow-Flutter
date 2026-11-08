import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final upcoming = app.appointments.where((a) => !a.isPast && a.status != AppointmentStatus.cancelled).toList();
    final past = app.appointments.where((a) => a.isPast || a.status == AppointmentStatus.cancelled).toList();
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(
        title: 'Mis citas',
        trailing: IconButton(
          onPressed: () => context.push('/p/book'),
          icon: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Próximas', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            Text('No tienes citas próximas.', style: GoogleFonts.inter(color: AppColors.slate500))
          else
            for (final item in upcoming) ...[
              _AppointmentTile(item: item),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          Text('Anteriores', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          for (final item in past) ...[
            _AppointmentTile(item: item),
            const SizedBox(height: 10),
          ],
          SolidButton(label: 'Reservar una cita', icon: Icons.calendar_month_outlined, onPressed: () => context.push('/p/book')),
        ],
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
                  color: cancelled ? AppColors.errorRed : AppColors.emerald600,
                  background: cancelled ? AppColors.errorBg : AppColors.emerald50,
                ),
                const SizedBox(height: 4),
                Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text('${item.weekday} · ${item.time} hrs', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                Text(item.storeName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.slate400),
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
      return const PatientScaffold(tab: PatientTab.appointments, topBar: DarkTopBar(title: 'Cita'), body: Center(child: Text('No encontramos esta cita.')));
    }
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(title: 'Detalle de cita', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusCapsule(item.status.label),
                const SizedBox(height: 8),
                Text(item.title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 8),
                Text('${item.weekday} ${item.day} de ${item.monthName}', style: GoogleFonts.inter(color: AppColors.slate600)),
                Text('${item.time} – ${item.endTime} hrs', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
                const Divider(height: 24),
                Text(item.storeName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text(item.storeAddress.isEmpty ? 'Sucursal OptiFlow' : item.storeAddress, style: GoogleFonts.inter(color: AppColors.slate500)),
                const SizedBox(height: 8),
                Text(item.professional, style: GoogleFonts.inter(color: AppColors.slate600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (item.status != AppointmentStatus.cancelled && !item.isPast) ...[
            SolidButton(label: 'Reprogramar', onPressed: () => context.push('/p/reschedule/${item.id}')),
            const SizedBox(height: 10),
            SolidButton(
              label: 'Cancelar cita',
              background: AppColors.white,
              foreground: AppColors.errorRed,
              border: AppColors.errorBg,
              onPressed: () {
                app.cancelAppointment(item.id);
                showAppMessage(context, 'Cita cancelada en este dispositivo.');
                context.pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class RescheduleScreen extends StatelessWidget {
  const RescheduleScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final item = app.appointmentById(id);
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(title: 'Reprogramar', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(item?.title ?? 'Cita', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          Text('Elige un nuevo horario. Si el backend no expone reprogramación, el cambio queda en la reserva nueva.', style: GoogleFonts.inter(color: AppColors.slate500)),
          const SizedBox(height: 16),
          SolidButton(label: 'Elegir nueva fecha', onPressed: () => context.push('/p/book')),
        ],
      ),
    );
  }
}
