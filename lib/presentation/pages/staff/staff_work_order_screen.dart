import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';
import 'package:logix_optiflow/features/production/presentation/production_view_model.dart';
import 'package:logix_optiflow/features/production/presentation/work_order_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

/// "17 nov 2026" a partir de una fecha ISO del backend.
String? workOrderDate(String? iso) {
  final date = DateTime.tryParse(iso ?? '');
  return date == null ? null : DateFormat('d MMM yyyy', 'es').format(date).replaceAll('.', '');
}

/// Orden de trabajo (`/s/work-order/{id}`), igual a Kotlin: el técnico y el admin la cambian; el resto solo la lee.
class WorkOrderScreen extends StatefulWidget {
  const WorkOrderScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<WorkOrderScreen> createState() => _WorkOrderScreenState();
}

class _WorkOrderScreenState extends State<WorkOrderScreen> {
  final _vm = getIt<WorkOrderViewModel>();
  final _reason = TextEditingController();
  final _date = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.load(widget.orderId);
  }

  @override
  void dispose() {
    _vm.dispose();
    _reason.dispose();
    _date.dispose();
    super.dispose();
  }

  void _toggleDelay(bool show) {
    _reason.clear();
    _date.clear();
    _vm.showDelay(show);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = getIt<SessionViewModel>().canOpen('/s/production');
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final order = state.order;
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Orden de trabajo', onBack: () => context.canPop() ? context.pop() : context.go('/s/production')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (state.loading)
                Text('Cargando...', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400))
              else if (order != null)
                ..._content(order, state, canEdit),
              if (state.message != null) ...[
                const SizedBox(height: 12),
                _Notice(state.message!, AppColors.emerald50, AppColors.emerald700),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 12),
                _Notice(state.error!, AppColors.errorBg, AppColors.errorRed),
              ],
            ],
          ),
        );
      },
    );
  }

  /// El técnico no carga el directorio de pacientes: el nombre sale de las órdenes del taller.
  String? _patientName(WorkOrderDetail order) {
    final id = order.patientId;
    if (id == null) return null;
    return getIt<StaffPatientsViewModel>().staffPatient(id)?.fullName ?? getIt<ProductionViewModel>().state.patientNames[id];
  }

  List<Widget> _content(WorkOrderDetail order, WorkOrderUiState state, bool canEdit) {
    final status = order.status;
    final finished = status == WorkOrderStatus.readyForDelivery || status == WorkOrderStatus.delivered;
    final inWorkshop = status == WorkOrderStatus.inWorkshop;
    final canMark = canEdit && inWorkshop && order.lenses.any((lens) => !lens.completed);
    final canSend = canEdit && (status == WorkOrderStatus.pending || inWorkshop);
    final next = WorkOrderStatus.next(status);
    final title = AppFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.staffInk);
    final body = AppFonts.inter(fontSize: 12, color: AppColors.staffInk);
    final link = AppFonts.inter(fontSize: 12, color: AppColors.staffAccent);
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFFDCE9FF), Color(0xFFF1F5FF)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StaffPill(WorkOrderStatus.label(status), background: AppColors.white),
            if (order.delayed && status != WorkOrderStatus.delivered) ...[
              const SizedBox(width: 8),
              const StaffPill('Atrasada', icon: LucideIcons.bell, background: AppColors.white),
            ],
          ]),
          const SizedBox(height: 14),
          Text('${order.code} · ${_patientName(order) ?? 'Paciente'}', style: AppFonts.inter(fontSize: 20, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text(
            status == WorkOrderStatus.delivered ? 'Entregada' : 'Entrega estimada: ${workOrderDate(order.estimatedDeliveryDate) ?? 'sin fecha'}',
            style: AppFonts.inter(fontSize: 11, color: AppColors.staffAccent),
          ),
          if (order.delayReason != null) ...[
            const SizedBox(height: 4),
            Text('Retraso: ${order.delayReason}', style: AppFonts.inter(fontSize: 11, color: AppColors.errorRed)),
          ],
        ]),
      ),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: Text('Lentes', style: title)),
        if (canMark) _Link('Marcar todos', _vm.completeAllLenses, link),
      ]),
      const SizedBox(height: 10),
      AppCard(
        radius: 18,
        borderColor: AppColors.staffBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(children: [
          if (order.lenses.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('Sin lentes', style: body)),
          for (final (index, lens) in order.lenses.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.staffBorder),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Icon(lens.completed ? LucideIcons.check : LucideIcons.clock, size: 18, color: lens.completed ? AppColors.emerald700 : AppColors.staffAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lens.specifications ?? 'Lente', style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                    Text(lens.completed ? 'Fabricado' : 'Por fabricar', style: AppFonts.inter(fontSize: 9, color: AppColors.slate400)),
                  ]),
                ),
                if (canEdit && inWorkshop && !lens.completed && lens.id != null) _Link('Marcar', () => _vm.completeLens(lens.id!), link),
              ]),
            ),
          ],
        ]),
      ),
      if (canEdit && status == WorkOrderStatus.pending) ...[
        const SizedBox(height: 6),
        Text('Los lentes se marcan cuando la orden está en el taller.', style: AppFonts.inter(fontSize: 10, color: AppColors.slate400)),
      ],
      const SizedBox(height: 20),
      Text('Técnico', style: title),
      const SizedBox(height: 6),
      Text(order.technician?.name ?? 'Sin asignar', style: body),
      if (canEdit && !finished && state.technicians.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final tech in state.technicians)
            StaffChip(tech.name, selected: tech.id == order.technician?.id, onTap: () {
              if (tech.id != order.technician?.id) _vm.assign(tech.id);
            }),
        ]),
      ],
      const SizedBox(height: 20),
      Text('Laboratorio', style: title),
      const SizedBox(height: 6),
      Text(order.laboratory?.name ?? 'Taller de la óptica', style: body),
      if (canSend && state.laboratories.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (final lab in state.laboratories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StaffChip(lab.name, selected: lab.id == order.laboratory?.id, onTap: () {
                if (lab.id != order.laboratory?.id) _vm.sendTo(lab.id);
              }),
            ),
          ),
      ],
      const SizedBox(height: 20),
      Text('Historial', style: title),
      const SizedBox(height: 8),
      AppCard(
        radius: 18,
        borderColor: AppColors.staffBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(children: [
          for (final change in order.statusHistory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(WorkOrderStatus.label(change.status), style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk))),
                Text(
                  change.changedAt == null ? '—' : DateFormat('d MMM · HH:mm', 'es').format(StoreTime.clock(change.changedAt!)).replaceAll('.', ''),
                  style: AppFonts.inter(fontSize: 11, color: AppColors.slate400),
                ),
              ]),
            ),
        ]),
      ),
      if (canEdit && status != WorkOrderStatus.delivered) ...[
        const SizedBox(height: 24),
        if (next != null)
          StaffButton(
            label: state.saving
                ? 'Guardando...'
                : next == WorkOrderStatus.delivered
                    ? 'Registrar entrega al paciente'
                    : 'Pasar a ${WorkOrderStatus.label(next).toLowerCase()}',
            icon: LucideIcons.chevronRight,
            onPressed: state.saving ? null : _vm.advance,
          ),
        const SizedBox(height: 12),
        if (state.showDelay) ...[
          const StaffLabel('Motivo del retraso'),
          const SizedBox(height: 6),
          StaffInput(
            controller: _reason,
            placeholder: 'Ej. El laboratorio no tiene el material',
            onChanged: _vm.setDelayReason,
            inputFormatters: [LengthLimitingTextInputFormatter(255)],
          ),
          const SizedBox(height: 10),
          const StaffLabel('Nueva fecha de entrega'),
          const SizedBox(height: 6),
          StaffInput(
            controller: _date,
            placeholder: 'dd/mm/aaaa',
            keyboardType: TextInputType.datetime,
            onChanged: _vm.setDelayDate,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')), LengthLimitingTextInputFormatter(10)],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: StaffButton(
                label: 'Cancelar',
                background: AppColors.white,
                foreground: AppColors.staffInk,
                border: AppColors.staffBorder,
                onPressed: () => _toggleDelay(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StaffButton(label: state.saving ? 'Guardando...' : 'Reportar', background: AppColors.errorRed, onPressed: state.saving ? null : _vm.reportDelay),
            ),
          ]),
        ] else
          StaffButton(
            label: 'Reportar retraso',
            background: AppColors.white,
            foreground: AppColors.errorRed,
            border: AppColors.staffBorder,
            onPressed: () => _toggleDelay(true),
          ),
      ],
    ];
  }
}

class _Link extends StatelessWidget {
  const _Link(this.text, this.onTap, this.style);
  final String text;
  final VoidCallback onTap;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: Text(text, style: style));
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, this.background, this.color);
  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: AppFonts.inter(fontSize: 12, color: color)),
    );
  }
}
