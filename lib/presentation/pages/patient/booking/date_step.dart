import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../models/ui_models.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class BookingDateStep extends StatelessWidget {
  const BookingDateStep({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final days = List.generate(7, (i) => app.weekStart.add(Duration(days: i)));
    final slots = app.slotsFor(app.selectedDate);
    final morning = slots.where((slot) => _hour(slot.time) < 13).toList();
    final afternoon = slots.where((slot) => _hour(slot.time) >= 13).toList();
    final month = DateFormat('MMMM yyyy', 'es').format(app.selectedDate ?? app.weekStart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MonthArrow(Icons.chevron_left, () => app.shiftWeek(-1)),
            Expanded(
              child: Text(
                month[0].toUpperCase() + month.substring(1),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
              ),
            ),
            _MonthArrow(Icons.chevron_right, () => app.shiftWeek(1)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final day in days) ...[
              Expanded(child: _DayCell(day)),
              if (day != days.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 22),
        if (app.bookingLoading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.electric)))
        else ...[
          if (slots.isEmpty) Text('No hay horarios disponibles para este día.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
          _SlotGroup('Mañana', morning),
          _SlotGroup('Tarde', afternoon),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF4F6FD), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const IconTile(icon: Icons.pie_chart_outline, background: AppColors.lavender, color: AppColors.electric),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.selectedSlot?.durationMinutes == null ? 'Selecciona un horario para ver su duración' : 'Duración: ${app.selectedSlot!.durationMinutes} min', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    Text('Llega 10 minutos antes de tu cita.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (app.bookingError != null) ...[
          const SizedBox(height: 12),
          Text(app.bookingError!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.errorRed)),
          TextButton(onPressed: app.bookingLoading ? null : app.continueFromStore, child: const Text('Actualizar horarios')),
        ],
        const SizedBox(height: 28),
        SolidButton(label: 'Continuar', onPressed: app.selectedSlot == null ? null : app.continueFromDate, loading: app.bookingLoading),
      ],
    );
  }

  int _hour(String time) => int.tryParse(time.split(':').first) ?? 0;
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F6FD),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 18, color: AppColors.deepNavy)),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(this.day);
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final selected = _same(app.selectedDate, day);
    final enabled = app.hasSlots(day);
    final weekday = DateFormat('E', 'es').format(day).replaceAll('.', '').toUpperCase();
    final fg = selected ? AppColors.white : (enabled ? AppColors.deepNavy : AppColors.slate300);
    return InkWell(
      onTap: enabled ? () => app.selectDate(day) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: selected ? AppColors.electric : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.deepNavy : AppColors.lavender, width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(weekday, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? AppColors.white : (enabled ? AppColors.slate600 : AppColors.slate300))),
            Text('${day.day}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
            if (selected) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2), decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  bool _same(DateTime? a, DateTime b) => a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SlotGroup extends StatelessWidget {
  const _SlotGroup(this.title, this.slots);
  final String title;
  final List<SlotOption> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    final app = context.watch<OptiFlowController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        const SizedBox(height: 10),
        for (var i = 0; i < slots.length; i += 4) ...[
          Row(
            children: [
              for (var col = 0; col < 4; col++) ...[
                if (col > 0) const SizedBox(width: 8),
                Expanded(
                  child: i + col < slots.length ? _SlotChip(slots[i + col], _active(app.selectedSlot, slots[i + col])) : const SizedBox(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  bool _active(SlotOption? selected, SlotOption slot) {
    if (selected == null) return false;
    return selected.id == slot.id;
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip(this.slot, this.active);
  final SlotOption slot;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.navyBlue : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.read<OptiFlowController>().selectSlot(slot),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? AppColors.navyBlue : AppColors.lavender)),
          child: Text(slot.label, style: GoogleFonts.inter(fontSize: 13, color: active ? AppColors.white : AppColors.deepNavy)),
        ),
      ),
    );
  }
}
