import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/models.dart';
import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

const _services = ['Examen de vista completo', 'Control de lentes', 'Adaptación de lentes de contacto'];
const _times = ['09:00', '10:30', '12:00', '14:30', '16:00', '17:00'];

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final items = app.appointments.where((item) {
      return switch (tab) {
        0 => !item.isPast && item.status != AppointmentStatus.cancelled,
        1 => item.isPast && item.status != AppointmentStatus.cancelled,
        _ => item.status == AppointmentStatus.cancelled,
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
        below: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              for (final entry in ['Próximas', 'Anteriores', 'Canceladas'].indexed) ...[
                if (entry.$1 > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TabChip(
                    label: entry.$2,
                    selected: tab == entry.$1,
                    onTap: () => setState(() => tab = entry.$1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => context.push('/p/book'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Reservar cita'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.skyTint,
                foregroundColor: AppColors.deepNavy,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              switch (tab) {
                0 => 'No tienes citas próximas.',
                1 => 'Aún no tienes citas anteriores.',
                _ => 'No tienes citas canceladas.',
              },
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
            ),
          for (final entry in grouped.entries) ...[
            Text(entry.key, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
            const SizedBox(height: 12),
            for (final item in entry.value) ...[
              _AppointmentTile(item: item),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.skyTint : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 38,
          child: Center(
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          ),
        ),
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
                  color: cancelled ? AppColors.errorRed : AppColors.deepNavy,
                  background: cancelled ? AppColors.errorBg : AppColors.white,
                ),
                const SizedBox(height: 4),
                Text(item.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text('${item.storeName} · ${item.time}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.slate500),
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
    final cancelled = item.status == AppointmentStatus.cancelled;
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(title: 'Detalle de cita', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDFE7FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC3D3F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusCapsule(item.status.label, color: AppColors.deepNavy, background: AppColors.white),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DateBadge(day: item.day, month: item.month),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          Text('${item.weekday} · ${item.time} a ${item.endTime}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
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
            child: Column(
              children: [
                _DetailLine(icon: Icons.place_outlined, label: 'Ubicación', value: item.storeName, extra: item.storeAddress),
                const Divider(height: 28, color: AppColors.lavender),
                _DetailLine(icon: Icons.person_outline, label: 'Profesional', value: item.professional),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBanner,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC3D3F5)),
            ),
            child: Row(
              children: [
                const IconTile(icon: Icons.notifications_none, background: Color(0xFFC7D5F7), color: AppColors.electric),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recordatorio activado', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text('Te avisaremos 24 horas antes.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!cancelled && !item.isPast) ...[
            const SizedBox(height: 18),
            SolidButton(
              label: 'Reprogramar cita',
              icon: Icons.edit_outlined,
              background: AppColors.white,
              foreground: AppColors.electric,
              border: AppColors.skyTint,
              onPressed: () => context.push('/p/reschedule/${item.id}'),
            ),
            TextButton(
              onPressed: () {
                app.cancelAppointment(item.id);
                showAppMessage(context, 'Cita cancelada');
                context.pop();
              },
              child: Text('Cancelar cita', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.electric)),
            ),
          ],
        ],
      ),
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
        Icon(icon, color: AppColors.electric, size: 18),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              if (extra != null && extra!.isNotEmpty) Text(extra!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
            ],
          ),
        ),
      ],
    );
  }
}

class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen({super.key, required this.id});
  final String id;

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  int service = 0;
  int store = 0;
  int time = 1;
  DateTime? date;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final item = app.appointmentById(widget.id);
    final storeNames = app.stores.isEmpty
        ? (app.bookingStores.isEmpty ? const ['Sucursal Centro', 'Sucursal Norte', 'Sucursal Providencia'] : app.bookingStores.map((s) => s.name).toList())
        : app.stores.map((s) => s.name).toList();
    final storeIndex = store.clamp(0, storeNames.length - 1);
    final dateLabel = date == null ? 'Selecciona una fecha' : _formatDate(date!);

    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(title: 'Detalle de cita', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reprograma cita', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navyBlue)),
                const SizedBox(height: 8),
                Text('Elige el servicio y el horario que mejor te convenga.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500)),
                if (item != null) ...[
                  const SizedBox(height: 6),
                  Text('Cita actual: ${item.weekday} ${item.day} · ${item.time}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                ],
                const SizedBox(height: 18),
                _label('Servicio'),
                _dropdown(_services, service, (value) => setState(() => service = value)),
                const SizedBox(height: 16),
                _label('Óptica'),
                _dropdown(storeNames, storeIndex, (value) => setState(() => store = value)),
                const SizedBox(height: 16),
                _label('Fecha'),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                  child: Container(
                    height: 46,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA8BCD9)),
                    ),
                    child: Text(dateLabel, style: GoogleFonts.inter(fontSize: 14, color: date == null ? AppColors.slate400 : AppColors.deepNavy)),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Horarios disponibles'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _times.length; i++)
                      SizedBox(
                        width: 96,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => setState(() => time = i),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: time == i ? const Color(0xFFBFDBFE) : AppColors.white,
                            side: BorderSide(color: time == i ? const Color(0xFFBFDBFE) : const Color(0xFFA8BCD9)),
                            foregroundColor: time == i ? AppColors.white : AppColors.deepNavy,
                          ),
                          child: Text(_times[i]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFDDEFFB), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF0E6A93), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Recibirás un recordatorio 24 horas antes de tu cita.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0E5A80)))),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SolidButton(
                  label: 'Confirmar reserva',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () {
                    if (date == null || item == null) {
                      showAppMessage(context, 'Selecciona una fecha');
                      return;
                    }
                    final chosen = storeNames[storeIndex];
                    final address = app.stores.where((s) => s.name == chosen).map((s) => s.address).firstOrNull ?? item.storeAddress;
                    app.rescheduleAppointment(
                      id: item.id,
                      title: _services[service],
                      storeName: chosen,
                      storeAddress: address,
                      date: date!,
                      time: _times[time],
                    );
                    showAppMessage(context, 'Solicitud de reprogramación enviada');
                    context.go('/p/appointments');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
    );
  }

  Widget _dropdown(List<String> options, int selected, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: selected,
      items: [for (var i = 0; i < options.length; i++) DropdownMenuItem(value: i, child: Text(options[i]))],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF4F8FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFA8BCD9))),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final text = DateFormat("EEEE d 'de' MMMM", 'es').format(value);
    return text[0].toUpperCase() + text.substring(1);
  }
}
