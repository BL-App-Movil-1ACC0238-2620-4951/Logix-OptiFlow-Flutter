import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../models/ui_models.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class BookingConfirmStep extends StatefulWidget {
  const BookingConfirmStep({super.key});

  @override
  State<BookingConfirmStep> createState() => _BookingConfirmStepState();
}

class _BookingConfirmStepState extends State<BookingConfirmStep> {
  late final TextEditingController reason;

  @override
  void initState() {
    super.initState();
    reason = TextEditingController(text: context.read<OptiFlowController>().bookingReason);
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final store = app.bookingStores[app.selectedStoreIndex];
    final slot = app.selectedSlot;
    final when = slot == null
        ? ''
        : '${_capital(DateFormat("EEEE, d 'de' MMMM", 'es').format(slot.date))} · ${slot.label}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lavender)),
                child: const Icon(Icons.calendar_today_outlined, color: AppColors.navyBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.skyTint)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 12, color: AppColors.electric),
                          const SizedBox(width: 4),
                          Text('Horario disponible', style: GoogleFonts.inter(fontSize: 11, color: AppColors.electric)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Reserva de cita', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                    Text(when, style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.electric, width: 1.5)),
                child: Text('?', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('La óptica asignará el tipo de atención', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text('Reservas el horario; la óptica revisará tu necesidad y confirmará el servicio correspondiente.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate600, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Detalle', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              _Row(Icons.place_outlined, 'Sucursal', _storeLabel(store)),
              const Divider(height: 1, color: AppColors.lavender),
              _Row(Icons.person_outline, 'Paciente', app.displayName),
              const Divider(height: 1, color: AppColors.lavender),
              const _Row(Icons.pie_chart_outline, 'Duración', '45 minutos'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Motivo de consulta', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        Text('Opcional', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
        const SizedBox(height: 10),
        TextField(
          controller: reason,
          onChanged: app.setReason,
          decoration: InputDecoration(
            hintText: 'Cuéntanos brevemente qué necesitas...',
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lavender)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lavender)),
          ),
        ),
        if (app.bookingError != null) ...[
          const SizedBox(height: 12),
          Text(app.bookingError!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.errorRed)),
        ],
        const SizedBox(height: 16),
        SolidButton(
          label: 'Reservar cita',
          loading: app.bookingLoading,
          onPressed: () async {
            final ok = await app.confirmBooking();
            if (!ok && context.mounted && app.bookingError != null) {
              showAppMessage(context, app.bookingError!);
            }
          },
        ),
      ],
    );
  }

  String _storeLabel(StoreOption store) => store.id != null ? store.name : 'Óptica Visión Norte · ${store.name}';

  String _capital(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          IconTile(icon: icon, background: const Color(0xFFEEF2FF), color: AppColors.navyBlue, size: 28, iconSize: 15),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
