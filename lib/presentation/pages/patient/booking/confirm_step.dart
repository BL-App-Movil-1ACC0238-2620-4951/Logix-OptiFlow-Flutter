import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class BookingConfirmStep extends StatelessWidget {
  const BookingConfirmStep({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final store = app.selectedBookingStore;
    final slot = app.selectedSlot;
    if (store == null || slot == null) return const Text('Selecciona una óptica y un horario.');
    final finishingReschedule = app.bookingAppointment != null && app.reschedulingId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Revisa tu reserva', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        AppCard(child: Column(
          children: [
            ListTile(leading: const Icon(Icons.place_outlined), title: Text(store.name), subtitle: Text(store.address)),
            const Divider(),
            ListTile(leading: const Icon(Icons.calendar_today_outlined), title: Text(DateFormat("EEEE d 'de' MMMM yyyy", 'es').format(slot.date)), subtitle: Text('${slot.label} · ${slot.durationMinutes ?? '-'} minutos')),
            const Divider(),
            ListTile(leading: const Icon(Icons.person_outline), title: Text(app.displayName), subtitle: Text(app.email)),
          ],
        )),
        const SizedBox(height: 16),
        const Text('La óptica asignará al profesional que realizará tu evaluación visual. Llega 10 minutos antes.'),
        if (app.bookingError != null) ...[
          const SizedBox(height: 16),
          Text(app.bookingError!, style: const TextStyle(color: AppColors.errorRed)),
        ],
        const SizedBox(height: 24),
        SolidButton(
          label: finishingReschedule ? 'Completar reprogramación' : app.reschedulingId == null ? 'Reservar cita' : 'Confirmar reprogramación',
          loading: app.bookingLoading,
          onPressed: () async { await app.confirmBooking(); },
        ),
      ],
    );
  }
}
