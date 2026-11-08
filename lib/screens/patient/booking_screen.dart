import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.storeId});
  final String? storeId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OptiFlowController>().prepareBooking(widget.storeId));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final titles = ['Elige una óptica', 'Fecha y hora', 'Confirma tu cita', 'Reserva enviada'];
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(
        title: 'Reservar cita',
        onBack: () {
          if (app.bookingStep > 1 && app.bookingStep < 4) {
            app.bookingBack();
          } else if (context.canPop()) {
            context.pop();
          } else {
            context.go('/p/home');
          }
        },
      ),
      body: app.bookingLoading && app.bookingStores.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.electric))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Paso ${app.bookingStep} de 4', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
                const SizedBox(height: 4),
                Text(titles[app.bookingStep - 1], style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: app.bookingStep / 4, color: AppColors.electric, backgroundColor: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 18),
                if (app.bookingError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(app.bookingError!, style: GoogleFonts.inter(color: AppColors.errorRed)),
                  ),
                if (app.bookingStep == 1) _Stores(app: app),
                if (app.bookingStep == 2) _Calendar(app: app),
                if (app.bookingStep == 3) _Confirm(app: app),
                if (app.bookingStep == 4) const _Done(),
              ],
            ),
    );
  }
}

class _Stores extends StatelessWidget {
  const _Stores({required this.app});
  final OptiFlowController app;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < app.bookingStores.length; i++) ...[
          AppCard(
            onTap: () => app.selectStore(i),
            child: Row(
              children: [
                Icon(app.selectedStoreIndex == i ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.electric),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.bookingStores[i].name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text(app.bookingStores[i].address, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                      Text('${app.bookingStores[i].distance} · ${app.bookingStores[i].availability}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.navyBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        SolidButton(label: 'Continuar', icon: Icons.arrow_forward_rounded, onPressed: app.continueFromStore),
      ],
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.app});
  final OptiFlowController app;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(5, (i) => app.weekStart.add(Duration(days: i)));
    final slots = app.slotsFor(app.selectedDate);
    final month = DateFormat('MMMM yyyy', 'es').format(app.selectedDate ?? app.weekStart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(onPressed: () => app.shiftWeek(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text(month[0].toUpperCase() + month.substring(1), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.deepNavy))),
            IconButton(onPressed: () => app.shiftWeek(1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: InkWell(
                    onTap: app.hasSlots(day) ? () => app.selectDate(day) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _same(app.selectedDate, day) ? AppColors.deepNavy : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: app.hasSlots(day) ? AppColors.skyTint : AppColors.slate200),
                      ),
                      child: Column(
                        children: [
                          Text(DateFormat('E', 'es').format(day).substring(0, 2).toUpperCase(), style: GoogleFonts.inter(fontSize: 11, color: _same(app.selectedDate, day) ? AppColors.white : AppColors.slate500)),
                          Text('${day.day}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _same(app.selectedDate, day) ? AppColors.white : AppColors.deepNavy)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Horarios', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in slots)
              ChoiceChip(
                label: Text(slot.label),
                selected: app.selectedSlot?.time == slot.time && _same(app.selectedSlot?.date, slot.date),
                onSelected: (_) => app.selectSlot(slot),
                selectedColor: AppColors.electric,
                labelStyle: GoogleFonts.inter(color: app.selectedSlot?.time == slot.time ? AppColors.white : AppColors.deepNavy),
              ),
          ],
        ),
        if (slots.isEmpty) Text('No hay horarios este día.', style: GoogleFonts.inter(color: AppColors.slate500)),
        const SizedBox(height: 16),
        TextField(
          onChanged: app.setReason,
          decoration: InputDecoration(
            labelText: 'Motivo (opcional)',
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SolidButton(label: 'Continuar', onPressed: app.continueFromDate, loading: app.bookingLoading),
      ],
    );
  }

  bool _same(DateTime? a, DateTime? b) => a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Confirm extends StatelessWidget {
  const _Confirm({required this.app});
  final OptiFlowController app;

  @override
  Widget build(BuildContext context) {
    final store = app.bookingStores[app.selectedStoreIndex];
    final slot = app.selectedSlot!;
    final when = DateFormat("EEEE d 'de' MMMM", 'es').format(slot.date);
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.displayName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 8),
              Text(store.name, style: GoogleFonts.inter(color: AppColors.slate600)),
              Text(store.address, style: GoogleFonts.inter(color: AppColors.slate500)),
              const SizedBox(height: 8),
              Text('${when[0].toUpperCase()}${when.substring(1)} · ${slot.time}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
              if (app.bookingReason.trim().isNotEmpty) Text('Motivo: ${app.bookingReason}', style: GoogleFonts.inter(color: AppColors.slate500)),
              if (app.bookingDemo) ...[
                const SizedBox(height: 8),
                Text('Horario de demostración: la reserva se simula si el backend no tiene cupos.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SolidButton(
          label: 'Confirmar reserva',
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
}

class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 72, color: AppColors.emerald600),
        const SizedBox(height: 12),
        Text('Tu cita quedó registrada', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        const SizedBox(height: 8),
        Text('Te avisaremos cuando se acerque el horario.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.slate500)),
        const SizedBox(height: 20),
        SolidButton(label: 'Ver mis citas', onPressed: () => context.go('/p/appointments')),
      ],
    );
  }
}
