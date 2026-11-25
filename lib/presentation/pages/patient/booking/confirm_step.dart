import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

const _ink = Color(0xFF111827);

class BookingConfirmStep extends StatelessWidget {
  const BookingConfirmStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingVm = getIt<BookingViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([bookingVm, sessionVm]),
      builder: (context, _) {
        final state = bookingVm.state;
        final store = state.selectedStore;
        final slot = state.selectedSlot;
        if (store == null || slot == null) return const Text('Selecciona una óptica y un horario.');
        final date = DateFormat("EEEE, d 'de' MMMM", 'es').format(slot.date);
        final finishingReschedule = state.appointment != null && state.reschedulingId != null;
        final name = sessionVm.displayName.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              borderColor: AppColors.lavender,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lavender),
                    ),
                    child: const Icon(LucideIcons.calendar, size: 20, color: AppColors.navyBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Pill('Horario disponible', background: AppColors.white, color: AppColors.electric, icon: LucideIcons.check, border: AppColors.skyTint),
                        const SizedBox(height: 4),
                        Text('Reserva de cita', style: AppFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                        const SizedBox(height: 4),
                        Text('${date[0].toUpperCase()}${date.substring(1)} · ${slot.label}', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              borderColor: AppColors.skyTint,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.electric, width: 1.5)),
                    child: Text('?', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('La óptica asignará el tipo de atención', style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                        Text(
                          'Reservas el horario; la óptica revisará tu necesidad y confirmará el servicio correspondiente.',
                          style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate600, height: 18 / 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Detalle', style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 10),
            AppCard(
              borderColor: AppColors.lavender,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _ConfirmRow(icon: LucideIcons.mapPin, label: 'Sucursal', value: store.name),
                  const Divider(height: 1, color: AppColors.lavender),
                  _ConfirmRow(icon: LucideIcons.userRound, label: 'Paciente', value: name.isEmpty ? 'Paciente' : name),
                  const Divider(height: 1, color: AppColors.lavender),
                  _ConfirmRow(icon: LucideIcons.chartPie, label: 'Duración', value: slot.durationMinutes == null ? '—' : '${slot.durationMinutes} minutos'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ErrorBanner(state.error),
            const SizedBox(height: 10),
            SolidButton(
              label: finishingReschedule
                  ? 'Completar reprogramación'
                  : state.reschedulingId == null
                      ? 'Reservar cita'
                      : 'Confirmar reprogramación',
              loading: state.loading,
              onPressed: () async {
                await bookingVm.confirmBooking();
              },
            ),
          ],
        );
      },
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          IconTile(icon: icon, background: const Color(0xFFEEF2FF), color: AppColors.navyBlue, size: 28, iconSize: 15, radius: 8),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400)),
                Text(value, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
