import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

const _ink = Color(0xFF111827);

class BookingDoneStep extends StatelessWidget {
  const BookingDoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingVm = getIt<BookingViewModel>();
    return ListenableBuilder(
      listenable: bookingVm,
      builder: (context, _) {
        final appointment = bookingVm.state.appointment;
        if (appointment == null) return const Text('No hay una reserva confirmada.');
        final confirmed = AppointmentStatusLabel.fromApi(appointment.status) == AppointmentStatus.confirmed;
        final rescheduled = bookingVm.state.reschedulingId != null;
        final start = StoreTime.clock(appointment.start);
        String upper(String pattern) => DateFormat(pattern, 'es').format(start).replaceAll('.', '').toUpperCase();
        return Column(
          children: [
            const SizedBox(height: 40),
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lavender))),
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(color: const Color(0xFFE6EBFD), shape: BoxShape.circle, border: Border.all(color: AppColors.lavender)),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, size: 30, color: AppColors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Text(
              rescheduled ? 'CITA REPROGRAMADA' : 'RESERVA ENVIADA',
              style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            Text('Tu horario fue reservado', textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                confirmed
                    ? 'Te esperamos en la óptica. Llega 10 minutos antes de tu cita.'
                    : 'La óptica revisará la solicitud y te notificará el tipo de atención.',
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500, height: 22 / 14),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Column(
                        children: [
                          Text(upper('EEE'), style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                          Text('${start.day}', style: AppFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
                          Text(upper('MMM'), style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SizedBox(height: 56, child: VerticalDivider(width: 1, color: AppColors.lavender, thickness: 1)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Pill(
                            confirmed ? 'Confirmada' : 'Pendiente de confirmación',
                            background: const Color(0xFFEEF2FF),
                            color: AppColors.electric,
                            icon: confirmed ? LucideIcons.check : LucideIcons.clock,
                            style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text('${DateFormat('HH:mm').format(start)} · Cita en óptica', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                          const SizedBox(height: 4),
                          Text(bookingVm.state.selectedStore?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SolidButton(
                label: 'Ver mis citas',
                textStyle: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                onPressed: () => context.go('/p/appointments'),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => context.go('/p/home'),
              child: Text('Volver al inicio', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.electric)),
            ),
          ],
        );
      },
    );
  }
}
