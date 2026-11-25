import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

class StaffPatientRecordScreen extends StatefulWidget {
  const StaffPatientRecordScreen({super.key, required this.id});
  final String id;
  @override
  State<StaffPatientRecordScreen> createState() => _StaffPatientRecordScreenState();
}

class _StaffPatientRecordScreenState extends State<StaffPatientRecordScreen> {
  static const _heroButton = Color(0xFF0013C1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getIt<StaffPatientsViewModel>().loadStaffRecord(widget.id);
      getIt<StaffPatientsViewModel>().loadOpenSales(widget.id);
    });
  }

  /// Se relee al volver de la venta, para que desaparezca la que se acaba de cerrar.
  Future<void> _openSale(String saleId) async {
    await context.push(Uri(path: '/s/sale', queryParameters: {'patientId': widget.id, 'saleId': saleId}).toString());
    if (mounted) getIt<StaffPatientsViewModel>().loadOpenSales(widget.id);
  }

  /// Se relee al volver, por si el taller avanzó la orden.
  Future<void> _openOrder(String orderId) async {
    await context.push('/s/work-order/$orderId');
    if (mounted) getIt<StaffPatientsViewModel>().loadStaffRecord(widget.id);
  }

  String _diopters(num? value) {
    final number = value ?? 0;
    return '${number > 0 ? '+' : ''}${number.toStringAsFixed(2)}';
  }

  String _date(DateTime value) => DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(value));

  Future<void> _cancel(String appointmentId, DateTime start) async {
    final error = await getIt<StaffPatientsViewModel>().cancelRecordAppointment(widget.id, appointmentId);
    if (error == null) getIt<AgendaViewModel>().refreshStaffAgenda(date: StoreTime.day(start));
    if (mounted) showAppMessage(context, error ?? 'Cita cancelada.');
  }

  @override
  Widget build(BuildContext context) {
    final patientsVm = getIt<StaffPatientsViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([patientsVm, sessionVm]),
      builder: (context, _) {
        final id = widget.id;
        final patient = patientsVm.staffPatient(id);
        final loading = patientsVm.state.recordLoading.contains(id);
        final errors = patientsVm.state.recordSectionErrors[id] ?? {};
        final records = patientsVm.state.recordClinical[id] ?? [];
        final examined = records.where((r) => r.status != 'PENDING' && r.examinationDate != null).toList()..sort((a, b) => b.examinationDate!.compareTo(a.examinationDate!));
        final prescriptions = records.where((r) => r.prescription != null).toList()..sort((a, b) => (b.examinationDate ?? DateTime.utc(1970)).compareTo(a.examinationDate ?? DateTime.utc(1970)));
        final last = prescriptions.firstOrNull;
        final rx = last?.prescription;
        final note = rx == null
            ? null
            : [
                if (rx.addition != null) 'Adición +${rx.addition!.toStringAsFixed(2)}',
                if (rx.treatment?.isNotEmpty == true) rx.treatment!,
                if (rx.recommendedFrameType?.isNotEmpty == true) 'Montura: ${rx.recommendedFrameType}',
              ].join(' · ');
        final next = (patientsVm.state.recordAppointments[id] ?? []).where((a) => const {'CONFIRMED', 'PENDING'}.contains(a.status) && a.end.isAfter(DateTime.now())).toList()..sort((a, b) => a.start.compareTo(b.start));
        final appointment = next.firstOrNull;
        final canStartCare = appointment != null && StoreTime.isoDay(StoreTime.day(appointment.start)) == StoreTime.isoDay(StoreTime.today());
        final orders = [...?patientsVm.state.recordOrders[id]]..sort((a, b) => (b.createdAt ?? DateTime.utc(1970)).compareTo(a.createdAt ?? DateTime.utc(1970)));
        final order = orders.where((o) => o.status != 'DELIVERED').firstOrNull ?? orders.firstOrNull;
        final openSales = sessionVm.canOpen('/s/sale') ? patientsVm.state.recordOpenSales[id] ?? const [] : const [];
        final lastVisit = examined.isEmpty ? 'Sin visitas' : _date(examined.first.examinationDate!);
        return StaffScaffold(
          tab: null, showBottomBar: false,
          topBar: StaffTopBar(title: 'Ficha del Paciente', onBack: () => context.canPop() ? context.pop() : context.go('/s/patients')),
          body: RefreshIndicator(onRefresh: () => patientsVm.loadStaffRecord(id), child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            if (patientsVm.state.recordErrors[id] != null) ...[
              ErrorBanner(patientsVm.state.recordErrors[id]),
              TextButton(onPressed: () => patientsVm.loadStaffRecord(id), child: const Text('Reintentar')),
            ] else if (patient == null && loading)
              const _EmptyCard('Cargando...'),
            if (patient != null) ...[
              StaffHero(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    StaffInitials(patient.initials, size: 64, fontSize: 16),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const StaffPill('Paciente activo', background: Color(0x3310B981), color: Color(0xFFA7F3D0)),
                      const SizedBox(height: 4),
                      Text(patient.fullName, style: AppFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: -0.6)),
                      Text('ID #${patient.ficha}', style: AppFonts.inter(fontSize: 10, color: AppColors.slate300)),
                    ])),
                  ]),
                  const SizedBox(height: 22),
                  Row(children: [Expanded(child: _HeroFact('TELÉFONO', patient.phone)), Expanded(child: _HeroFact('ÚLTIMA VISITA', lastVisit))]),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: StaffButton(label: 'Llamar', icon: LucideIcons.phone, background: AppColors.white, foreground: _heroButton, height: 46, onPressed: () {})),
                    const SizedBox(width: 10),
                    Expanded(child: StaffButton(label: 'Mensaje', icon: LucideIcons.mail, background: AppColors.white, foreground: _heroButton, height: 46, onPressed: () {})),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              const StaffSectionTitle('Última prescripción'),
              const SizedBox(height: 12),
              if (errors['clinical'] != null) _EmptyCard(errors['clinical']!, error: true)
              else if (rx == null) _EmptyCard(loading ? 'Cargando...' : 'Aún no tiene recetas registradas.')
              else _StaffCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(LucideIcons.eye, size: 26, color: AppColors.staffAccent),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Última Prescripción', style: AppFonts.inter(fontSize: 18, color: AppColors.staffInk)),
                    Text(last?.examinationDate == null ? 'Sin fecha' : _date(last!.examinationDate!), style: AppFonts.inter(fontSize: 8, color: AppColors.staffInk)),
                  ])),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _EyeBox('Ojo derecho', '${_diopters(rx.sphereOd)} / ${_diopters(rx.cylinderOd)}', 'Eje ${rx.axisOd ?? 0}°')),
                  const SizedBox(width: 8),
                  Expanded(child: _EyeBox('Ojo izquierdo', '${_diopters(rx.sphereOs)} / ${_diopters(rx.cylinderOs)}', 'Eje ${rx.axisOs ?? 0}°')),
                ]),
                if (note?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _EyeBox.tint, borderRadius: BorderRadius.circular(12)),
                    child: Text(note!, style: AppFonts.inter(fontSize: 13, color: AppColors.staffAccent)),
                  ),
                ],
              ])),
              const SizedBox(height: 24),
              const StaffSectionTitle('Próxima cita'),
              const SizedBox(height: 12),
              if (errors['appointments'] != null) _EmptyCard(errors['appointments']!, error: true)
              else if (appointment == null) _EmptyCard(loading ? 'Cargando...' : 'No tiene citas próximas.')
              else ...[
                _StaffCard(
                  onTap: () => context.push('/s/agenda'),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 60,
                      decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(12)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${StoreTime.clock(appointment.start).day}', style: AppFonts.inter(fontSize: 20, color: AppColors.staffInk)),
                        Text(DateFormat('MMM', 'es').format(StoreTime.clock(appointment.start)).replaceAll('.', '').toUpperCase(), style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      StaffPill(appointment.status == 'PENDING' ? 'Pendiente' : 'Confirmada'),
                      const SizedBox(height: 4),
                      Text('Evaluación visual completa', style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                      const SizedBox(height: 4),
                      Text('${DateFormat('HH:mm').format(StoreTime.clock(appointment.start))} · Evaluación visual', style: AppFonts.inter(fontSize: 10, color: AppColors.slate400)),
                    ])),
                    const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
                  ]),
                ),
                // Quien agenda (asesor, optometrista o admin) también puede cancelar.
                if (sessionVm.canOpen('/s/agenda')) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _cancel(appointment.id, appointment.start),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(patientsVm.state.cancelling ? 'Cancelando...' : 'Cancelar cita', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 13, color: AppColors.staffAccent)),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              StaffSectionTitle(
                'Proceso de sus lentes',
                action: order == null ? null : 'Orden OT-${order.id.substring(0, order.id.length < 4 ? order.id.length : 4).toUpperCase()}',
                onAction: order == null ? null : () => _openOrder(order.id),
              ),
              const SizedBox(height: 12),
              if (errors['orders'] != null) _EmptyCard(errors['orders']!, error: true)
              else if (order == null) _EmptyCard(loading ? 'Cargando...' : 'El paciente no tiene órdenes de trabajo.')
              else _StaffCard(onTap: () => _openOrder(order.id), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const StaffIconTile(LucideIcons.settings, size: 36, background: _StaffCard.soft),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    StaffPill(order.label, icon: LucideIcons.clock),
                    const SizedBox(height: 4),
                    Text(order.detail, style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                  ])),
                  const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i <= order.step ? AppColors.staffAccent : AppColors.staffChip, borderRadius: BorderRadius.circular(99)))),
                  ],
                ]),
                const SizedBox(height: 8),
                Text(
                  order.status == 'DELIVERED' ? 'Entregada' : 'Entrega estimada: ${order.dueDate ?? 'sin fecha'}${order.delayed ? ' (atrasada)' : ''}',
                  style: AppFonts.inter(fontSize: 9, color: AppColors.staffAccent),
                ),
              ])),
              if (openSales.isNotEmpty) ...[
                const SizedBox(height: 24),
                const StaffSectionTitle('Ventas por cerrar'),
                const SizedBox(height: 12),
                for (final sale in openSales)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StaffCard(
                      onTap: () => _openSale(sale.id),
                      child: Row(children: [
                        const StaffIconTile(LucideIcons.fileText, size: 36, background: _StaffCard.soft),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          StaffPill(sale.statusLabel, icon: LucideIcons.clock),
                          const SizedBox(height: 4),
                          Text(sale.detail, style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                        ])),
                        const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
                      ]),
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: StaffButton(label: 'Nueva cita', icon: LucideIcons.calendar, onPressed: () => context.push(Uri(path: '/s/appointments/new', queryParameters: {'patientId': id}).toString()))),
                if (sessionVm.canOpen('/s/clinical')) ...[
                  const SizedBox(width: 10),
                  Expanded(child: StaffButton(
                    label: 'Iniciar atención',
                    icon: LucideIcons.plus,
                    background: AppColors.white,
                    foreground: AppColors.staffInk,
                    border: AppColors.staffBorder,
                    onPressed: () {
                      if (canStartCare) {
                        context.push(Uri(path: '/s/clinical', queryParameters: {'patientId': id, 'appointmentId': appointment.id}).toString());
                      } else {
                        showAppMessage(context, 'El paciente no tiene una cita para hoy');
                      }
                    },
                  )),
                ],
              ]),
              if (sessionVm.canOpen('/s/quote')) ...[
                const SizedBox(height: 10),
                StaffButton(label: 'Crear cotización', icon: LucideIcons.fileText, onPressed: () => context.push(Uri(path: '/s/quote', queryParameters: {'patientId': id}).toString())),
              ],
              if (errors.isNotEmpty) TextButton(onPressed: () => patientsVm.loadStaffRecord(id), child: const Text('Volver a cargar la ficha')),
            ],
          ])),
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.child, this.onTap});
  static const soft = Color(0xFFF1F5FF);
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(onTap: onTap, radius: 18, borderColor: AppColors.staffBorder, padding: const EdgeInsets.all(14), child: child);
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text, {this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      borderColor: AppColors.staffBorder,
      child: Text(text, style: AppFonts.inter(fontSize: 12, color: error ? AppColors.errorRed : AppColors.slate400)),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.inter(fontSize: 8, color: AppColors.slate300)),
        const SizedBox(height: 6),
        Text(value, style: AppFonts.inter(fontSize: 15, color: AppColors.white)),
      ],
    );
  }
}

class _EyeBox extends StatelessWidget {
  const _EyeBox(this.label, this.value, this.detail);
  static const tint = Color(0xFFEEF2FF);
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.inter(fontSize: 8, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text(value, style: AppFonts.inter(fontSize: 17, color: AppColors.staffInk)),
          const SizedBox(height: 4),
          Text(detail, style: AppFonts.inter(fontSize: 8, color: AppColors.staffAccent)),
        ],
      ),
    );
  }
}
