import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

export 'package:logix_optiflow/presentation/pages/staff/staff_clinical_care_screen.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});
  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final dni = TextEditingController();
  final birth = TextEditingController();
  @override
  void dispose() { name.dispose(); email.dispose(); phone.dispose(); dni.dispose(); birth.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final patientsVm = getIt<StaffPatientsViewModel>();
    return ListenableBuilder(
      listenable: patientsVm,
      builder: (context, _) {
        final busy = patientsVm.state.saving;
        void back() { if (!busy) { context.canPop() ? context.pop() : context.go('/s/patients'); } }
        return StaffScaffold(
          tab: null, showBottomBar: false,
          topBar: StaffTopBar(title: 'Nuevo Cliente', onBack: back),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            StaffHero(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Row(children: [
                const StaffIconTile(LucideIcons.fileText, size: 36, background: AppColors.white, radius: 10),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FICHA DIGITAL', style: AppFonts.inter(fontSize: 9, color: _accentLight, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text('Registro rápido de paciente', style: AppFonts.inter(fontSize: 18, color: AppColors.white)),
                  const SizedBox(height: 6),
                  Text('El paciente podrá entrar a la app con su correo y su DNI como contraseña.', style: AppFonts.inter(fontSize: 9, color: AppColors.white.withValues(alpha: 0.85))),
                ])),
              ]),
            ),
            const SizedBox(height: 18),
            const StaffLabel('Nombre completo'),
            const SizedBox(height: 10),
            StaffInput(controller: name, enabled: !busy, placeholder: 'Camila Paz Morales', icon: LucideIcons.user, inputFormatters: [LengthLimitingTextInputFormatter(80)]),
            const SizedBox(height: 20),
            const StaffLabel('Correo electrónico'),
            const SizedBox(height: 10),
            StaffInput(controller: email, enabled: !busy, placeholder: 'camila@correo.com', icon: LucideIcons.mail, keyboardType: TextInputType.emailAddress, inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))]),
            const SizedBox(height: 20),
            const StaffLabel('Teléfono móvil'),
            const SizedBox(height: 10),
            StaffInput(controller: phone, enabled: !busy, placeholder: '987 654 321', icon: LucideIcons.phone, keyboardType: TextInputType.phone, inputFormatters: [LengthLimitingTextInputFormatter(20)]),
            const SizedBox(height: 20),
            const StaffLabel('DNI', trailing: 'Será su contraseña temporal'),
            const SizedBox(height: 10),
            StaffInput(controller: dni, enabled: !busy, placeholder: '45879632', icon: LucideIcons.creditCard, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)]),
            const SizedBox(height: 20),
            const StaffLabel('Fecha de nacimiento', trailing: 'Opcional · dd/mm/aaaa'),
            const SizedBox(height: 10),
            StaffInput(controller: birth, enabled: !busy, placeholder: '24/05/1990', icon: LucideIcons.calendar, keyboardType: TextInputType.datetime, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')), LengthLimitingTextInputFormatter(10)]),
            if (patientsVm.state.saveError != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(patientsVm.state.saveError),
            ],
            const SizedBox(height: 28),
            StaffButton(label: busy ? 'Guardando...' : 'Guardar paciente', icon: LucideIcons.check, onPressed: busy ? null : () async {
              final id = await patientsVm.registerStaffPatient(name: name.text, email: email.text, phone: phone.text, dni: dni.text, birthDate: birth.text);
              if (!context.mounted || id == null) return;
              showAppMessage(context, 'Paciente registrado');
              context.replace('/s/patient/${Uri.encodeComponent(id)}');
            }),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: back,
                child: Text('Cancelar', style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffAccent)),
              ),
            ),
          ]),
        );
      },
    );
  }
}

const _accentLight = Color(0xFF60A5FA);

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key, this.patientId});
  final String? patientId;
  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  bool choosingPatient = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<AgendaViewModel>().prepareStaffBooking(patientId: widget.patientId); });
  }

  @override
  Widget build(BuildContext context) {
    final agendaVm = getIt<AgendaViewModel>();
    final patientsVm = getIt<StaffPatientsViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([agendaVm, patientsVm]),
      builder: (context, _) {
        final patient = agendaVm.state.bookingPatientId == null ? null : patientsVm.staffPatient(agendaVm.state.bookingPatientId!);
        final days = {for (final slot in agendaVm.state.bookingSlots) StoreTime.day(slot.start)}.toList();
        final slots = agendaVm.state.bookingSlots.where((slot) => agendaVm.state.bookingDay != null && StoreTime.isoDay(StoreTime.day(slot.start)) == StoreTime.isoDay(agendaVm.state.bookingDay!)).toList();
        final busy = agendaVm.state.bookingSaving;
        return StaffScaffold(
          tab: null, showBottomBar: false,
          topBar: StaffTopBar(title: 'Nueva cita', onBack: () { if (!busy) { context.canPop() ? context.pop() : context.go('/s/agenda'); } }),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            StaffHero(
              radius: 20,
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const StaffIconTile(LucideIcons.calendar, size: 36, background: AppColors.white, radius: 10),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AGENDAMIENTO · PASO ÚNICO', style: AppFonts.inter(fontSize: 9, color: _accentLight, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Datos de la cita', style: AppFonts.inter(fontSize: 18, color: AppColors.white)),
                ])),
              ]),
            ),
            const SizedBox(height: 18),
            const StaffLabel('Paciente', trailing: 'Registrado en OptiFlow'),
            const SizedBox(height: 8),
            StaffSelect(
              text: patient?.fullName ?? 'Elegir paciente',
              icon: patient == null ? LucideIcons.user : null,
              leading: patient == null ? null : StaffInitials(patient.initials, size: 28, fontSize: 9),
              onTap: () { if (!busy) setState(() => choosingPatient = !choosingPatient); },
            ),
            if (choosingPatient) ...[
              const SizedBox(height: 8),
              if (patientsVm.state.error != null) ...[
                ErrorBanner(patientsVm.state.error),
                TextButton(onPressed: patientsVm.refreshStaffPatients, child: const Text('Reintentar')),
              ] else if (patientsVm.state.loading && patientsVm.state.patients.isEmpty)
                const _EmptyCard('Cargando pacientes...')
              else if (patientsVm.state.patients.isEmpty)
                const _EmptyCard('Todavía no hay pacientes registrados.')
              else
                AppCard(
                  radius: 18,
                  borderColor: AppColors.staffBorder,
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final option in patientsVm.state.patients)
                      InkWell(
                        onTap: busy ? null : () {
                          agendaVm.selectStaffBooking(patientId: option.id);
                          setState(() => choosingPatient = false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            StaffInitials(option.initials, size: 28, fontSize: 9),
                            const SizedBox(width: 12),
                            Expanded(child: Text(option.fullName, style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk))),
                          ]),
                        ),
                      ),
                  ]),
                ),
            ],
            const SizedBox(height: 22),
            const StaffSectionTitle('Fecha', action: 'Turnos libres de tu óptica'),
            const SizedBox(height: 12),
            if (agendaVm.state.bookingLoading)
              const _EmptyCard('Cargando horarios...')
            else if (days.isEmpty)
              const _EmptyCard('No hay turnos libres. El administrador puede abrirlos en Más > Horarios de atención.')
            else ...[
              _ChoiceGrid(
                labels: [for (final day in days) DateFormat('EEE d MMM', 'es').format(day)],
                selected: days.indexWhere((day) => day == agendaVm.state.bookingDay),
                onSelect: (i) { if (!busy) agendaVm.selectStaffBooking(day: days[i]); },
              ),
              const SizedBox(height: 12),
              const StaffSectionTitle('Hora', action: 'Selecciona horario'),
              const SizedBox(height: 12),
              _ChoiceGrid(
                labels: [for (final slot in slots) DateFormat('HH:mm').format(StoreTime.clock(slot.start))],
                selected: slots.indexWhere((slot) => slot.id == agendaVm.state.bookingSlotId),
                onSelect: (i) { if (!busy) agendaVm.selectStaffBooking(slotId: slots[i].id); },
              ),
            ],
            if (agendaVm.state.bookingError != null) ...[
              const SizedBox(height: 8),
              Text(agendaVm.state.bookingError!, style: AppFonts.inter(fontSize: 12, color: const Color(0xFFDC2626))),
              TextButton(onPressed: busy ? null : agendaVm.reloadStaffBookingSlots, child: const Text('Actualizar horarios')),
            ],
            const SizedBox(height: 14),
            StaffButton(label: busy ? 'Agendando...' : 'Confirmar cita', icon: LucideIcons.check, onPressed: busy || agendaVm.state.bookingLoading ? null : () async {
              final booked = await agendaVm.confirmStaffBooking();
              if (!context.mounted || !booked) return;
              showAppMessage(context, 'Cita agendada.');
              if (context.canPop()) { context.pop(); } else { context.go('/s/agenda'); }
            }),
          ]),
        );
      },
    );
  }
}

/// Opciones en filas de 3, como el selector de horas de Kotlin.
class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.labels, required this.selected, required this.onSelect});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var row = 0; row < labels.length; row += 3)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            for (var i = row; i < row + 3; i++) ...[
              if (i > row) const SizedBox(width: 10),
              Expanded(
                child: i >= labels.length
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: () => onSelect(i),
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == selected ? AppColors.staffAccent : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: i == selected ? AppColors.staffAccent : AppColors.staffBorder),
                          ),
                          child: Text(labels[i], maxLines: 1, style: AppFonts.inter(fontSize: 13, color: i == selected ? AppColors.white : AppColors.staffInk)),
                        ),
                      ),
              ),
            ],
          ]),
        ),
    ]);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(radius: 18, borderColor: AppColors.staffBorder, child: Text(text, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)));
  }
}

/// Tablero del taller por etapas (`/s/production` y `/s/production/{ESTADO}`), igual a Kotlin.
class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key, this.initialStage});

  /// Estado del backend (PENDING, IN_WORKSHOP, …) de la pestaña con que se abre.
  final String? initialStage;

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  late ProductionStage stage = switch (WorkOrderStatus.order.indexOf(widget.initialStage ?? '')) {
    final index when index >= 0 => ProductionStage.values[index],
    _ => ProductionStage.inWorkshop,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<ProductionViewModel>().refreshStaffOrders(); });
  }

  @override
  Widget build(BuildContext context) {
    final productionVm = getIt<ProductionViewModel>();
    return ListenableBuilder(
      listenable: productionVm,
      builder: (context, _) {
        final orders = productionVm.productionOrders;
        final visible = orders.where((order) => order.stage == stage).toList();
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Producción', onBack: () => context.canPop() ? context.pop() : context.go('/s/home')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in ProductionStage.values) ...[
                      _StageChip(
                        count: orders.where((order) => order.stage == item).length,
                        label: item.label,
                        selected: item == stage,
                        muted: item == ProductionStage.pending && item != stage,
                        onTap: () => setState(() => stage = item),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text('${stage.label} · ${visible.length}', style: AppFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
              const SizedBox(height: 14),
              if (productionVm.state.loading && orders.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (productionVm.state.error != null && orders.isEmpty)
                Column(children: [
                  Text(productionVm.state.error!, style: AppFonts.inter(fontSize: 13, color: AppColors.slate400)),
                  TextButton(onPressed: productionVm.refreshStaffOrders, child: const Text('Reintentar')),
                ])
              else if (visible.isEmpty) Text('No hay órdenes en esta etapa.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
              for (final order in visible) ...[
                _OrderCard(order, stage.label, onTap: () async {
                  await context.push('/s/work-order/${order.id}');
                  productionVm.refreshStaffOrders();
                }),
                const SizedBox(height: 10),
              ],
              if (orders.isNotEmpty || (!productionVm.state.loading && productionVm.state.error == null)) ...[
                const SizedBox(height: 6),
                Text('Órdenes sincronizadas con el backend.', style: AppFonts.inter(fontSize: 10, color: AppColors.slate400)),
              ],
            ],
          ),
        );
        },
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.count, required this.label, required this.selected, required this.muted, required this.onTap});
  final int count;
  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF1E3D79) : (muted ? const Color(0xFFAAB6DD) : AppColors.white);
    final fg = selected ? AppColors.white : AppColors.staffHeader;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 94,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF1E3D79) : AppColors.lavender),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: AppFonts.inter(fontSize: 13, color: fg)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 8, color: selected ? AppColors.white : AppColors.staffInk)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order, this.stageLabel, {required this.onTap});
  final ProductionOrder order;
  final String stageLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 18,
      borderColor: AppColors.staffBorder,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              order.needsAttention ? const StaffPill('Requiere atención', icon: LucideIcons.bell) : StaffPill(stageLabel, icon: LucideIcons.clock),
              const Spacer(),
              Text(order.code, style: AppFonts.inter(fontSize: 9, color: AppColors.staffInk)),
            ],
          ),
          const SizedBox(height: 12),
          Text(order.patient, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
          const SizedBox(height: 4),
          Text(order.detail, style: AppFonts.inter(fontSize: 9, color: AppColors.staffMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: AppColors.staffAccent),
              const SizedBox(width: 8),
              Text(order.due, style: AppFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
            ],
          ),
        ],
      ),
    );
  }
}
