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
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

const _softBorder = Color(0xFFC3D3F5);
const _fieldBorder = Color(0xFFA8BCD9);

/// La cita ya se atendió: el backend la marcó como completada o su horario ya pasó.
bool _attended(AppointmentUi item) =>
    item.status == AppointmentStatus.completed || (item.isPast && item.status != AppointmentStatus.cancelled);

void _back(BuildContext context, String fallback) => context.canPop() ? context.pop() : context.go(fallback);

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _vm = getIt<PatientViewModel>();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.refreshAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final items = state.appointments.where((item) {
          final cancelled = item.status == AppointmentStatus.cancelled;
          return switch (_tab) {
            0 => !_attended(item) && !cancelled,
            1 => _attended(item),
            _ => cancelled,
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
            onBack: () => _back(context, '/p/home'),
            below: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (i, label) in const ['Próximas', 'Anteriores', 'Canceladas'].indexed)
                    SegmentChip(
                      text: label,
                      selected: _tab == i,
                      onTap: () => setState(() => _tab = i),
                      selectedBg: AppColors.skyTint,
                      selectedText: AppColors.deepNavy,
                      unselectedText: AppColors.deepNavy,
                      style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _vm.refreshAppointments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.push('/p/book'),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: AppColors.skyTint, borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.plus, size: 16, color: AppColors.deepNavy),
                          const SizedBox(width: 10),
                          Text('Reservar cita', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.deepNavy)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (state.appointmentsLoading && state.appointments.isEmpty) const LinearProgressIndicator(),
                ErrorBanner(state.appointmentsError),
                if (!state.appointmentsLoading && state.appointmentsError == null && items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      switch (_tab) {
                        0 => 'No tienes citas próximas.',
                        1 => 'Aún no tienes citas anteriores.',
                        _ => 'No tienes citas canceladas.',
                      },
                      style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500),
                    ),
                  ),
                for (final entry in grouped.entries) ...[
                  Text(entry.key, style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                  const SizedBox(height: 12),
                  for (final item in entry.value) ...[
                    _AppointmentCard(item: item, onTap: () => context.push('/p/appointment/${item.id}')),
                    const SizedBox(height: 18),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.item, required this.onTap});
  final AppointmentUi item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: AppColors.lavender,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DateBadge(day: item.day, month: item.month, background: const Color(0xFFEEF2FF)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusCapsule(item.status.label),
                const SizedBox(height: 5),
                Text(item.title, style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 5),
                Text('${item.storeName} · ${item.time}', style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.slate500),
        ],
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _confirmCancel(BuildContext context, PatientViewModel vm, AppointmentUi item) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('¿Cancelar la cita?', style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        content: Text(
          'Se liberará tu horario en ${item.storeName}. Si la necesitas después, tendrás que reservar otra.',
          style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('No', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Sí, cancelar', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final cancelled = await vm.cancelAppointment(item.id);
    if (!context.mounted) return;
    showAppMessage(context, cancelled ? 'Cita cancelada' : vm.state.appointmentActionError ?? 'No se pudo cancelar la cita.');
    if (cancelled) _back(context, '/p/appointments');
  }

  @override
  Widget build(BuildContext context) {
    final vm = getIt<PatientViewModel>();
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final item = vm.appointmentById(id);
        final topBar = DarkTopBar(title: 'Detalle de cita', onBack: () => _back(context, '/p/appointments'));
        if (item == null) {
          return PatientScaffold(
            tab: PatientTab.appointments,
            topBar: topBar,
            body: Center(
              child: vm.state.appointmentsLoading
                  ? const CircularProgressIndicator(color: AppColors.electric)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.state.appointmentsError ?? 'No encontramos esta cita.', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
                        TextButton(onPressed: vm.refreshAppointments, child: const Text('Volver a cargar')),
                      ],
                    ),
            ),
          );
        }
        final attended = _attended(item);
        final active = item.status != AppointmentStatus.cancelled && !attended;
        final busy = vm.state.appointmentActionLoading;
        final storeId = item.opticalStoreId;
        return PatientScaffold(
          tab: PatientTab.appointments,
          topBar: topBar,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(34, 22, 34, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE7FC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.status == AppointmentStatus.confirmed || item.status == AppointmentStatus.completed ? LucideIcons.check : LucideIcons.clock,
                            size: 13,
                            color: AppColors.deepNavy,
                          ),
                          const SizedBox(width: 6),
                          Text(item.status.label, style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 54,
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.day, style: AppFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy, height: 1.1)),
                              Text(item.month, style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                              Text('${item.weekday} · ${item.time} a ${item.endTime}', style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
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
                radius: 20,
                borderColor: AppColors.lavender,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _DetailLine(icon: LucideIcons.mapPin, label: 'Ubicación', value: item.storeName, extra: item.storeAddress),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.lavender),
                    const SizedBox(height: 14),
                    _DetailLine(icon: LucideIcons.user, label: 'Profesional', value: item.professional),
                  ],
                ),
              ),
              if (!attended) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoBanner,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Row(
                    children: [
                      const IconTile(icon: LucideIcons.bell, background: Color(0xFFC7D5F7), color: AppColors.electric, iconSize: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recordatorio activado', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            Text('Te avisaremos 24 horas antes.', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (attended && storeId != null) ...[
                const SizedBox(height: 14),
                _RateStoreCard(storeId: storeId, storeName: item.storeName, rated: vm.state.ratedStoreIds.contains(storeId)),
              ],
              if (active) ...[
                const SizedBox(height: 20),
                SolidButton(
                  label: 'Reprogramar cita',
                  leadingIcon: LucideIcons.pencil,
                  background: AppColors.white,
                  foreground: AppColors.electric,
                  border: AppColors.skyTint,
                  height: 48,
                  textStyle: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  onPressed: busy ? null : () => context.push('/p/reschedule/${item.id}'),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: busy ? null : () => _confirmCancel(context, vm, item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      busy ? 'Cancelando…' : 'Cancelar cita',
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.electric),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
        Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon, color: AppColors.electric, size: 18)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400)),
              Text(value, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              if (extra != null && extra!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(extra!, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Calificación de 1 a 5 estrellas de la óptica de una cita atendida.
class _RateStoreCard extends StatefulWidget {
  const _RateStoreCard({required this.storeId, required this.storeName, required this.rated});
  final String storeId;
  final String storeName;
  final bool rated;

  @override
  State<_RateStoreCard> createState() => _RateStoreCardState();
}

class _RateStoreCardState extends State<_RateStoreCard> {
  final _comment = TextEditingController();
  int _score = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_score == 0) {
      showAppMessage(context, 'Elige de 1 a 5 estrellas');
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    final error = await getIt<PatientViewModel>().rateStore(widget.storeId, _score, _comment.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) showAppMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      borderColor: AppColors.lavender,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: widget.rated
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Gracias por calificar!', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 4),
                Text('Tu opinión ayuda a otros pacientes a elegir óptica.', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Califica tu visita', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 4),
                Text('¿Cómo te atendieron en ${widget.storeName}?', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var value = 1; value <= 5; value++) ...[
                      if (value > 1) const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _score = value),
                        child: Icon(LucideIcons.star, size: 30, color: value <= _score ? AppColors.electric : AppColors.slate300),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comment,
                  maxLength: 280,
                  minLines: 1,
                  maxLines: 3,
                  style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.deepNavy),
                  decoration: InputDecoration(
                    hintText: 'Comentario (opcional)',
                    hintStyle: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate400),
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _fieldBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electric)),
                  ),
                ),
                const SizedBox(height: 12),
                SolidButton(
                  label: _sending ? 'Enviando...' : 'Enviar calificación',
                  height: 46,
                  textStyle: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  onPressed: _send,
                ),
              ],
            ),
    );
  }
}

/// Reprogramar: elige óptica, fecha y horario. Se reserva el nuevo horario y luego se cancela la cita anterior.
class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen({super.key, required this.id});
  final String id;

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  final _vm = getIt<BookingViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _vm.prepareBooking(null, rescheduleId: widget.id);
      if (mounted && _vm.state.stores.isNotEmpty) await _vm.continueFromStore();
    });
  }

  Future<void> _pickDate() async {
    final today = StoreTime.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.state.selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Elige una fecha',
    );
    if (picked != null) _vm.selectDate(picked);
  }

  Future<void> _confirm() async {
    if (_vm.state.loading) return;
    if (_vm.state.stores.isEmpty) {
      showAppMessage(context, 'No se pudieron cargar las ópticas. Intenta de nuevo.');
      return;
    }
    if (_vm.state.selectedDate == null) {
      showAppMessage(context, 'Selecciona una fecha');
      return;
    }
    if (_vm.state.selectedSlot == null) {
      showAppMessage(context, 'Selecciona un horario');
      return;
    }
    if (_vm.state.step == 2 && !_vm.continueFromDate()) {
      showAppMessage(context, _vm.state.error ?? 'Selecciona un horario');
      return;
    }
    final done = await _vm.confirmBooking();
    if (!mounted) return;
    showAppMessage(context, done ? 'Cita reprogramada' : _vm.state.error ?? 'No se pudo reprogramar la cita.');
    if (done) context.go('/p/appointments');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final slots = _vm.slotsFor(state.selectedDate);
        final date = state.selectedDate;
        final dateText = date == null ? '' : DateFormat("EEEE d 'de' MMMM", 'es').format(date);
        return PatientScaffold(
          tab: PatientTab.appointments,
          topBar: DarkTopBar(title: 'Detalle de cita', onBack: () => _back(context, '/p/appointments')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reprograma cita', style: AppFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navyBlue)),
                    const SizedBox(height: 10),
                    Text('Elige la óptica y el horario que mejor te convenga.', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
                    const SizedBox(height: 18),
                    const _FormLabel('Óptica'),
                    if (state.stores.isEmpty)
                      Text(
                        state.loading ? 'Cargando ópticas...' : state.error ?? 'No se pudieron cargar las ópticas. Revisa tu conexión e intenta de nuevo.',
                        style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500),
                      )
                    else
                      _Dropdown(
                        options: [for (final s in state.stores) s.name],
                        selected: state.selectedStoreIndex,
                        onSelect: (i) async {
                          _vm.selectStore(i);
                          await _vm.continueFromStore();
                        },
                      ),
                    const SizedBox(height: 18),
                    const _FormLabel('Fecha'),
                    _FieldBox(onTap: _pickDate, child: Text(dateText.isEmpty ? '' : dateText[0].toUpperCase() + dateText.substring(1), style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.deepNavy))),
                    const SizedBox(height: 18),
                    const _FormLabel('Horarios disponibles'),
                    if (state.loading)
                      const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: AppColors.electric)))
                    else if (slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('No hay horarios disponibles para esta fecha.', style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
                      ),
                    if (!state.loading)
                      for (var i = 0; i < slots.length; i += 3) ...[
                        Row(
                          children: [
                            for (var j = i; j < i + 3; j++) ...[
                              if (j > i) const SizedBox(width: 8),
                              Expanded(child: j < slots.length ? _TimeChip(slot: slots[j], selected: state.selectedSlot?.id == slots[j].id, onTap: () => _vm.selectSlot(slots[j])) : const SizedBox()),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFDDEFFB), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendarClock, size: 20, color: Color(0xFF0E6A93)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Recibirás un recordatorio 24 horas antes de tu cita.', style: AppFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF0E5A80))),
                          ),
                        ],
                      ),
                    ),
                    if (state.stores.isNotEmpty && state.error != null) ...[
                      const SizedBox(height: 12),
                      ErrorBanner(state.error),
                    ],
                    const SizedBox(height: 18),
                    SolidButton(
                      label: state.appointment != null ? 'Completar reprogramación' : 'Confirmar reserva',
                      leadingIcon: LucideIcons.calendarPlus,
                      height: 48,
                      loading: state.loading && state.step == 3,
                      textStyle: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
      );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _fieldBorder),
          ),
          child: child,
        ),
      );
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      color: AppColors.white,
      onSelected: onSelect,
      itemBuilder: (_) => [
        for (final (i, option) in options.indexed)
          PopupMenuItem(value: i, child: Text(option, style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.deepNavy))),
      ],
      child: _FieldBox(
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected >= 0 && selected < options.length ? options[selected] : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.deepNavy),
              ),
            ),
            const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.deepNavy),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.slot, required this.selected, required this.onTap});
  final SlotOption slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedBg = Color(0xFFBFDBFE);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? selectedBg : _fieldBorder),
        ),
        child: Text(slot.label, style: AppFonts.plusJakartaSans(fontSize: 15, color: selected ? AppColors.white : AppColors.deepNavy)),
      ),
    );
  }
}
