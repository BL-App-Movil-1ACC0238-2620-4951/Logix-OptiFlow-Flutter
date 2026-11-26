import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/domain/agenda_item.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_forms.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/clinical/presentation/clinical_care_flow.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/clinical/presentation/clinical_care_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

const _staffSoft = Color(0xFFF1F5FF);

/// Atención clínica de una cita, igual a Kotlin: examen, antecedentes y receta; al final la cita queda completada.
class ClinicalCareScreen extends StatefulWidget {
  const ClinicalCareScreen({super.key, this.patientId, this.appointmentId});
  final String? patientId;
  final String? appointmentId;
  @override
  State<ClinicalCareScreen> createState() => _ClinicalCareScreenState();
}

class _ClinicalCareScreenState extends State<ClinicalCareScreen> {
  bool get hasContext => widget.patientId?.isNotEmpty == true && widget.appointmentId?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _load(); });
  }

  @override
  void didUpdateWidget(covariant ClinicalCareScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientId != oldWidget.patientId || widget.appointmentId != oldWidget.appointmentId) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _load(); });
    }
  }

  Future<void> _load() async {
    if (hasContext) {
      await getIt<ClinicalCareViewModel>().start(widget.patientId!, widget.appointmentId!);
    } else {
      await getIt<AgendaViewModel>().refreshStaffAgenda(date: StoreTime.today());
    }
  }

  void _back(ClinicalCareFlow? flow) {
    if (flow?.saving == true) return;
    if (flow?.back() == true) return;
    context.canPop() ? context.pop() : context.go('/s/agenda');
  }

  @override
  Widget build(BuildContext context) {
    final agendaVm = getIt<AgendaViewModel>();
    final careVm = getIt<ClinicalCareViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([agendaVm, careVm]),
      builder: (context, _) {
        final current = careVm.flow;
        final flow = hasContext && current?.patientId == widget.patientId && current?.appointmentId == widget.appointmentId ? current : null;
        final editablePrescription = flow?.step == CareStep.prescription && flow?.prescriptionSaved == false;
        return PopScope(
          canPop: flow?.saving != true && !editablePrescription,
          onPopInvokedWithResult: (didPop, _) { if (!didPop && flow?.saving != true) flow?.back(); },
          child: StaffScaffold(
            tab: null,
            showBottomBar: false,
            topBar: StaffTopBar(title: 'Atención clínica', onBack: () => _back(flow)),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (!hasContext)
                  ..._appointmentPicker(agendaVm)
                else if (flow == null)
                  const _CenteredNote('Cargando la ficha de la cita...')
                else ...[
                  _CareHero(flow),
                  const SizedBox(height: 18),
                  if (flow.loading)
                    const _CenteredNote('Cargando la ficha de la cita...')
                  else if (flow.loadError != null) ...[
                    _CenteredNote(flow.loadError!),
                    const SizedBox(height: 14),
                    StaffButton(label: 'Reintentar', icon: LucideIcons.clock, onPressed: flow.load),
                  ] else ...[
                    if (flow.step != CareStep.done) ...[
                      _StepIndicator(flow.step.index),
                      const SizedBox(height: 20),
                    ],
                    ...switch (flow.step) {
                      CareStep.examination => _examination(flow),
                      CareStep.history => _history(flow),
                      CareStep.prescription => _prescription(flow),
                      CareStep.done => _done(flow),
                    },
                    if (flow.error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(flow.error!, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sin cita en la ruta (por ejemplo desde Más): se elige una cita de hoy.
  List<Widget> _appointmentPicker(AgendaViewModel agendaVm) {
    final today = StoreTime.isoDay(StoreTime.today());
    final candidates = agendaVm.state.agenda
        .where((item) =>
            item.status != AgendaStatus.done &&
            item.endsAt?.isAfter(DateTime.now()) == true &&
            item.startsAt != null &&
            StoreTime.isoDay(StoreTime.day(item.startsAt!)) == today)
        .toList();
    return [
      const _StepTitle('Selecciona la cita', 'Elige la cita de hoy que vas a atender.'),
      const SizedBox(height: 14),
      if (agendaVm.state.loading) const _CenteredNote('Cargando la agenda...'),
      if (agendaVm.state.error != null) ErrorBanner(agendaVm.state.error),
      if (!agendaVm.state.loading && agendaVm.state.error == null && candidates.isEmpty) const _CenteredNote('No hay citas pendientes para atender hoy.'),
      for (final item in candidates)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            radius: 18,
            borderColor: AppColors.staffBorder,
            padding: const EdgeInsets.all(14),
            onTap: () => context.push(Uri(path: '/s/clinical', queryParameters: {'patientId': item.patientId, 'appointmentId': item.appointmentId!}).toString()),
            child: Row(children: [
              StaffInitials(_initialsOf(item.name)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                const SizedBox(height: 4),
                Text('${item.time} · ${item.service}', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
              ])),
              const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      StaffButton(
        label: 'Actualizar citas',
        icon: LucideIcons.refreshCw,
        background: AppColors.white,
        foreground: AppColors.staffInk,
        border: AppColors.staffBorder,
        onPressed: agendaVm.state.loading ? null : _load,
      ),
    ];
  }

  List<Widget> _examination(ClinicalCareFlow flow) => [
        const _StepTitle('Registrar examen', 'Abre la ficha clínica de esta cita con lo observado en la consulta.'),
        const SizedBox(height: 14),
        StaffLabel('Observaciones', trailing: '${flow.observations.length}/500'),
        const SizedBox(height: 8),
        _CareInput(flow, 'observations', flow.observations, (v) => flow.observations = v,
            placeholder: 'Motivo de consulta, agudeza visual, hallazgos...', maxLength: 500, lines: 5),
        const SizedBox(height: 20),
        StaffButton(label: flow.saving ? 'Guardando...' : 'Registrar examen', icon: LucideIcons.check, onPressed: flow.saving ? null : flow.saveExamination),
      ];

  List<Widget> _history(ClinicalCareFlow flow) => [
        const _StepTitle('Antecedentes médicos', 'Sepáralos con comas. Puedes dejar vacío lo que no aplique.'),
        if (flow.observations.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _staffSoft, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('OBSERVACIONES DEL EXAMEN', style: AppFonts.inter(fontSize: 8, color: AppColors.staffAccent, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(flow.observations, style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        const StaffLabel('Alergias'),
        const SizedBox(height: 8),
        _CareInput(flow, 'allergies', flow.allergies, (v) => flow.allergies = v, placeholder: 'Penicilina, polen'),
        const SizedBox(height: 16),
        const StaffLabel('Enfermedades previas'),
        const SizedBox(height: 8),
        _CareInput(flow, 'conditions', flow.previousConditions, (v) => flow.previousConditions = v, placeholder: 'Diabetes, hipertensión'),
        const SizedBox(height: 16),
        StaffLabel('Antecedentes oculares familiares', trailing: '${flow.familyHistory.length}/1000'),
        const SizedBox(height: 8),
        _CareInput(flow, 'family', flow.familyHistory, (v) => flow.familyHistory = v,
            placeholder: 'Glaucoma en la madre, miopía alta en el padre...', maxLength: 1000, lines: 4),
        const SizedBox(height: 20),
        StaffButton(label: flow.saving ? 'Guardando...' : 'Guardar antecedentes', icon: LucideIcons.chevronRight, onPressed: flow.saving ? null : flow.saveHistory),
      ];

  List<Widget> _prescription(ClinicalCareFlow flow) {
    final form = flow.prescription;
    final locked = flow.prescriptionSaved;
    Widget eyeRow(String eye, String key, String sphere, String cylinder, String axis,
        ValueChanged<String> onSphere, ValueChanged<String> onCylinder, ValueChanged<String> onAxis) {
      Widget cell(String k, String value, ValueChanged<String> update, {bool isAxis = false}) => Expanded(
            child: _CareInput(flow, '$k$key', value, update,
                placeholder: isAxis ? '0' : '0.00', numeric: true, axis: isAxis, maxLength: isAxis ? 3 : 6, readOnly: locked, compact: true),
          );
      return Row(children: [
        SizedBox(width: 28, child: Text(eye, style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.staffAccent))),
        cell('sphere', sphere, onSphere),
        const SizedBox(width: 6),
        cell('cylinder', cylinder, onCylinder),
        const SizedBox(width: 6),
        cell('axis', axis, onAxis, isAxis: true),
      ]);
    }

    return [
      const _StepTitle('Receta óptica', 'Esfera y cilindro en dioptrías (ej. -1.75); eje en grados de 0 a 180.'),
      if (locked) ...[
        const SizedBox(height: 12),
        Text('La receta ya está guardada. Reintenta para cerrar la cita.', style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
      ],
      const SizedBox(height: 14),
      AppCard(
        radius: 18,
        borderColor: AppColors.staffBorder,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 34),
            for (final label in ['Esfera', 'Cilindro', 'Eje'])
              Expanded(child: Text(label, textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 10, color: AppColors.slate400))),
          ]),
          const SizedBox(height: 8),
          eyeRow('OD', 'OD', form.sphereOD, form.cylinderOD, form.axisOD, (v) => form.sphereOD = v, (v) => form.cylinderOD = v, (v) => form.axisOD = v),
          const SizedBox(height: 8),
          eyeRow('OI', 'OS', form.sphereOS, form.cylinderOS, form.axisOS, (v) => form.sphereOS = v, (v) => form.cylinderOS = v, (v) => form.axisOS = v),
        ]),
      ),
      const SizedBox(height: 16),
      const StaffLabel('Adición (cerca)', trailing: 'Opcional · 0 a 4'),
      const SizedBox(height: 8),
      _CareInput(flow, 'addition', form.addition, (v) => form.addition = v, placeholder: '2.00', numeric: true, maxLength: 6, readOnly: locked),
      const SizedBox(height: 16),
      const StaffLabel('Tratamiento', trailing: 'Opcional'),
      const SizedBox(height: 8),
      _CareInput(flow, 'treatment', form.treatment, (v) => form.treatment = v, placeholder: 'Antirreflejo, filtro de luz azul', maxLength: 255, readOnly: locked),
      const SizedBox(height: 16),
      const StaffLabel('Tipo de montura recomendada', trailing: 'Opcional'),
      const SizedBox(height: 8),
      _CareInput(flow, 'frame', form.recommendedFrameType, (v) => form.recommendedFrameType = v, placeholder: 'Completa de acetato', maxLength: 255, readOnly: locked),
      const SizedBox(height: 20),
      StaffButton(
        label: flow.saving ? 'Guardando...' : locked ? 'Reintentar cierre de cita' : 'Guardar receta y finalizar',
        icon: LucideIcons.check,
        onPressed: flow.saving ? null : flow.savePrescriptionAndFinish,
      ),
      if (!locked) ...[
        const SizedBox(height: 10),
        StaffButton(
          label: 'Volver a antecedentes',
          background: AppColors.white,
          foreground: AppColors.staffInk,
          border: AppColors.staffBorder,
          onPressed: flow.saving ? null : flow.back,
        ),
      ],
    ];
  }

  List<Widget> _done(ClinicalCareFlow flow) => [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.emerald700, shape: BoxShape.circle),
              child: const Icon(LucideIcons.check, size: 24, color: AppColors.white),
            ),
            const SizedBox(height: 12),
            Text('Atención finalizada', style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.emerald700)),
            const SizedBox(height: 6),
            Text(
              'La ficha clínica y la receta quedaron guardadas y la cita figura como completada.',
              textAlign: TextAlign.center,
              style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        StaffButton(label: 'Ver ficha del paciente', icon: LucideIcons.user, onPressed: () => context.replace('/s/patient/${Uri.encodeComponent(flow.patientId)}')),
        const SizedBox(height: 10),
        StaffButton(
          label: 'Volver a la agenda',
          icon: LucideIcons.calendar,
          background: AppColors.white,
          foreground: AppColors.staffInk,
          border: AppColors.staffBorder,
          onPressed: () => context.go('/s/agenda'),
        ),
      ];
}

String _initialsOf(String name) => name.split(' ').where((p) => p.trim().isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

class _CareHero extends StatelessWidget {
  const _CareHero(this.flow);
  final ClinicalCareFlow flow;

  @override
  Widget build(BuildContext context) {
    final name = flow.patient?.fullName ?? 'Paciente';
    final date = flow.appointment == null ? null : StoreTime.clock(flow.appointment!.start);
    final today = date != null && StoreTime.isoDay(date) == StoreTime.isoDay(StoreTime.today());
    return StaffHero(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(children: [
        Row(children: [
          const Icon(LucideIcons.clock, size: 14, color: AppColors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              flow.step == CareStep.done ? 'Atención finalizada' : 'Atención en curso',
              style: AppFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.white),
            ),
          ),
          if (date != null)
            Text('${today ? 'Hoy' : DateFormat('d MMM', 'es').format(date)} · ${DateFormat('HH:mm').format(date)}', style: AppFonts.inter(fontSize: 9, color: AppColors.slate300)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          StaffInitials(flow.patient?.initials ?? _initialsOf(name), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppFonts.inter(fontSize: 14, color: AppColors.white)),
              Text('Evaluación visual', style: AppFonts.inter(fontSize: 9, color: AppColors.slate300)),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator(this.current);
  final int current;
  static const _labels = ['Examen', 'Antecedentes', 'Receta'];

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < _labels.length; i++)
        Expanded(
          child: Column(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: i <= current ? AppColors.staffAccent : _staffSoft, shape: BoxShape.circle),
              child: i < current
                  ? const Icon(LucideIcons.check, size: 14, color: AppColors.white)
                  : Text('${i + 1}', style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: i == current ? AppColors.white : AppColors.staffAccent)),
            ),
            const SizedBox(height: 6),
            Text(_labels[i], style: AppFonts.inter(fontSize: 10, fontWeight: i == current ? FontWeight.w700 : FontWeight.w400, color: AppColors.staffInk)),
          ]),
        ),
    ]);
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
      const SizedBox(height: 6),
      Text(subtitle, style: AppFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
    ]);
  }
}

class _CenteredNote extends StatelessWidget {
  const _CenteredNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Text(text, textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 13, color: AppColors.slate400)),
    );
  }
}

/// Campo con el estilo de `StaffInput` que guarda en el flujo. Se reconstruye con `formRevision`.
class _CareInput extends StatelessWidget {
  const _CareInput(
    this.flow,
    this.keyName,
    this.value,
    this.update, {
    required this.placeholder,
    this.maxLength,
    this.lines = 1,
    this.numeric = false,
    this.axis = false,
    this.readOnly = false,
    this.compact = false,
  });

  final ClinicalCareFlow flow;
  final String keyName;
  final String value;
  final ValueChanged<String> update;
  final String placeholder;
  final int? maxLength;
  final int lines;
  final bool numeric;
  final bool axis;
  final bool readOnly;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.slate200));
    return TextFormField(
      key: ValueKey('${flow.formRevision}-$keyName'),
      initialValue: value,
      enabled: !flow.saving && !readOnly,
      minLines: lines,
      maxLines: lines,
      textAlign: compact ? TextAlign.center : TextAlign.start,
      keyboardType: numeric ? TextInputType.numberWithOptions(decimal: !axis, signed: !axis) : null,
      inputFormatters: [
        if (axis) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      cursorColor: AppColors.staffAccent,
      style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.staffField,
        hintText: placeholder,
        hintStyle: AppFonts.inter(fontSize: lines == 1 ? 14 : 12, color: AppColors.slate400),
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 6 : 14, vertical: compact ? 13 : (lines == 1 ? 15 : 12)),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.staffAccent)),
      ),
      onChanged: (v) {
        update(v);
        flow.changed();
      },
    );
  }
}
