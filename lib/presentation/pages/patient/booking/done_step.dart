import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/appointment.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class BookingDoneStep extends StatelessWidget {
  const BookingDoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final appointment = app.bookingAppointment;
    if (appointment == null) return const Text('No hay una reserva confirmada.');
    final store = app.selectedBookingStore;
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.electric, size: 96),
        const SizedBox(height: 20),
        Text(app.reschedulingId == null ? 'Tu cita está reservada' : 'Tu cita fue reprogramada', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        AppCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusCapsule(AppointmentStatusLabel.fromApi(appointment.status).label),
            const SizedBox(height: 12),
            Text(store?.name ?? 'Óptica'),
            Text(store?.address ?? ''),
            const SizedBox(height: 8),
            Text(DateFormat("EEEE d 'de' MMMM yyyy · HH:mm", 'es').format(appointment.start)),
            const SizedBox(height: 8),
            SelectableText('Reserva: ${appointment.id}', style: Theme.of(context).textTheme.bodySmall),
          ],
        )),
        const SizedBox(height: 24),
        SolidButton(label: 'Ver mis citas', onPressed: () => context.go('/p/appointments')),
        TextButton(onPressed: () => context.go('/p/home'), child: const Text('Volver al inicio')),
      ],
    );
  }
}
