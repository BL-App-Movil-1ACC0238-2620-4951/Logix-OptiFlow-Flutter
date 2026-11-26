import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class BookingConfirmStep extends StatelessWidget {
  const BookingConfirmStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingVm = getIt<BookingViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([bookingVm, sessionVm]),
      builder: (context, _) {
        final store = bookingVm.state.selectedStore;
        final slot = bookingVm.state.selectedSlot;
        if (store == null || slot == null) return const Text('Selecciona una óptica y un horario.');
        final finishingReschedule = bookingVm.state.appointment != null && bookingVm.state.reschedulingId != null;
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
                ListTile(leading: const Icon(Icons.person_outline), title: Text(sessionVm.displayName), subtitle: Text(sessionVm.email)),
              ],
            )),
            const SizedBox(height: 16),
            const Text('La óptica asignará al profesional que realizará tu evaluación visual. Llega 10 minutos antes.'),
            if (bookingVm.state.error != null) ...[
              const SizedBox(height: 16),
              Text(bookingVm.state.error!, style: const TextStyle(color: AppColors.errorRed)),
            ],
            const SizedBox(height: 24),
            SolidButton(
              label: finishingReschedule ? 'Completar reprogramación' : bookingVm.state.reschedulingId == null ? 'Reservar cita' : 'Confirmar reprogramación',
              loading: bookingVm.state.loading,
              onPressed: () async { await bookingVm.confirmBooking(); },
            ),
          ],
        );
        },
    );
  }
}
