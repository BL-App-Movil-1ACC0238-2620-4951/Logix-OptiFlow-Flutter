import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/agenda_item.dart';
import '../../../domain/entities/clinical_forms.dart';
import '../../../domain/entities/store_time.dart';
import '../../state/clinical_care_flow.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

class ClinicalCareScreen extends StatefulWidget {
  const ClinicalCareScreen({super.key, this.patientId, this.appointmentId});
  final String? patientId;
  final String? appointmentId;
  @override
  State<ClinicalCareScreen> createState() => _ClinicalCareScreenState();
}

class _ClinicalCareScreenState extends State<ClinicalCareScreen> {
  bool get hasContext =>
      widget.patientId?.isNotEmpty == true &&
      widget.appointmentId?.isNotEmpty == true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant ClinicalCareScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientId != oldWidget.patientId ||
        widget.appointmentId != oldWidget.appointmentId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final app = context.read<OptiFlowController>();
    if (hasContext) {
      await app.startClinicalCare(widget.patientId!, widget.appointmentId!);
    } else {
      await app.refreshStaffAgenda(date: StoreTime.today());
    }
  }

  void _back(ClinicalCareFlow? flow) {
    if (flow?.saving == true) return;
    if (flow?.back() == true) return;
    context.canPop() ? context.pop() : context.go('/s/agenda');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final current = app.clinicalCare;
    final flow = hasContext &&
            current?.patientId == widget.patientId &&
            current?.appointmentId == widget.appointmentId
        ? current
        : null;
    final editablePrescription =
        flow?.step == CareStep.prescription && flow?.prescriptionSaved == false;
    return PopScope(
      canPop: flow?.saving != true && !editablePrescription,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && flow?.saving != true) flow?.back();
      },
      child: StaffScaffold(
        tab: null,
        showBottomBar: false,
        topBar:
            StaffTopBar(title: 'Atención clínica', onBack: () => _back(flow)),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (!hasContext)
                ..._appointmentPicker(app)
              else if (flow == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                _hero(flow),
                const SizedBox(height: 18),
                if (flow.loading)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          Center(child: Text('Cargando la ficha de la cita…')))
                else if (flow.loadError != null) ...[
                  Text(flow.loadError!,
                      style: const TextStyle(color: AppColors.errorRed)),
                  const SizedBox(height: 14),
                  SolidButton(label: 'Reintentar', onPressed: flow.load),
                ] else ...[
                  if (flow.step != CareStep.done) ...[
                    Row(children: [
                      for (final entry
                          in ['Examen', 'Antecedentes', 'Receta'].indexed)
                        Expanded(
                            child: Column(children: [
                          CircleAvatar(
                              radius: 15,
                              backgroundColor: entry.$1 <= flow.step.index
                                  ? AppColors.staffAccent
                                  : AppColors.staffChip,
                              child: Text(
                                  entry.$1 < flow.step.index
                                      ? '✓'
                                      : '${entry.$1 + 1}',
                                  style: const TextStyle(
                                      color: AppColors.white, fontSize: 12))),
                          const SizedBox(height: 6),
                          Text(entry.$2,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: entry.$1 == flow.step.index
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ])),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  ...switch (flow.step) {
                    CareStep.examination => _examination(flow),
                    CareStep.history => _history(flow),
                    CareStep.prescription => _prescription(flow),
                    CareStep.done => _done(flow),
                  },
                  if (flow.error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(flow.error!,
                                style: const TextStyle(
                                    color: AppColors.errorRed)))),
                ],
              ],
            ]),
      ),
    );
  }

  List<Widget> _appointmentPicker(OptiFlowController app) {
    final today = StoreTime.isoDay(StoreTime.today());
    final candidates = app.agenda
        .where((item) =>
            item.status != AgendaStatus.done &&
            item.endsAt?.isAfter(DateTime.now()) == true &&
            item.startsAt != null &&
            StoreTime.isoDay(StoreTime.day(item.startsAt!)) == today)
        .toList();
    return [
      const Text('Selecciona la cita que vas a atender.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      if (app.staffAgendaLoading) const LinearProgressIndicator(),
      if (app.staffAgendaError != null)
        Text(app.staffAgendaError!,
            style: const TextStyle(color: AppColors.errorRed)),
      if (!app.staffAgendaLoading &&
          app.staffAgendaError == null &&
          candidates.isEmpty)
        const Text('No hay citas pendientes para atender hoy.'),
      for (final item in candidates)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => context.push(Uri(
                  path: '/s/clinical',
                  queryParameters: {
                    'patientId': item.patientId,
                    'appointmentId': item.appointmentId!
                  }).toString()),
              child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text('${item.time} · ${item.service}'),
                  trailing: const Icon(Icons.chevron_right)),
            )),
      TextButton(
          onPressed: app.staffAgendaLoading ? null : _load,
          child: const Text('Actualizar citas')),
    ];
  }

  Widget _hero(ClinicalCareFlow flow) {
    final name = flow.patient?.fullName ?? 'Paciente';
    final date = flow.appointment == null
        ? null
        : StoreTime.clock(flow.appointment!.start);
    final today = date != null &&
        StoreTime.isoDay(date) == StoreTime.isoDay(StoreTime.today());
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
            color: AppColors.staffHeader,
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.schedule, color: AppColors.white, size: 14),
            const SizedBox(width: 6),
            Expanded(
                child: Text(
                    flow.step == CareStep.done
                        ? 'Atención finalizada'
                        : 'Atención en curso',
                    style:
                        const TextStyle(color: AppColors.white, fontSize: 10))),
            if (date != null)
              Text(
                  '${today ? 'Hoy' : DateFormat('d MMM', 'es').format(date)} · ${DateFormat('HH:mm').format(date)}',
                  style:
                      const TextStyle(color: AppColors.slate300, fontSize: 10)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lavender,
                child: Text(flow.patient?.initials ?? 'P',
                    style: const TextStyle(
                        color: AppColors.electric, fontSize: 12))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.white)),
                  const Text('Evaluación visual',
                      style: TextStyle(fontSize: 10, color: AppColors.slate300))
                ])),
          ]),
        ]));
  }

  Widget _title(String title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.staffAccent)),
        const SizedBox(height: 14)
      ]);

  Widget _field(ClinicalCareFlow flow, String keyName, String label,
          String value, ValueChanged<String> update,
          {String? hint,
          int? maxLength,
          int lines = 1,
          bool numeric = false,
          bool axis = false,
          bool readOnly = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          key: ValueKey('${flow.formRevision}-$keyName'),
          initialValue: value,
          enabled: !flow.saving && !readOnly,
          maxLength: maxLength,
          maxLines: lines,
          keyboardType: numeric
              ? TextInputType.numberWithOptions(decimal: !axis, signed: !axis)
              : null,
          inputFormatters:
              axis ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: AppColors.white),
          onChanged: (value) {
            update(value);
            flow.changed();
          },
        ),
      );

  List<Widget> _examination(ClinicalCareFlow flow) => [
        _title('Registrar examen',
            'Abre la ficha clínica de esta cita con lo observado en la consulta.'),
        _field(flow, 'observations', 'Observaciones', flow.observations,
            (value) => flow.observations = value,
            hint: 'Motivo de consulta, agudeza visual, hallazgos…',
            maxLength: 500,
            lines: 4),
        SolidButton(
            label: 'Registrar examen',
            loading: flow.saving,
            icon: Icons.check,
            onPressed: () async {
              await flow.saveExamination();
            }),
      ];

  List<Widget> _history(ClinicalCareFlow flow) => [
        _title('Antecedentes médicos',
            'Sepáralos con comas. Puedes dejar vacío lo que no aplique.'),
        if (flow.observations.isNotEmpty) ...[
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('OBSERVACIONES DEL EXAMEN',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.staffAccent)),
                const SizedBox(height: 4),
                Text(flow.observations)
              ])),
          const SizedBox(height: 16)
        ],
        _field(flow, 'allergies', 'Alergias', flow.allergies,
            (value) => flow.allergies = value,
            hint: 'Penicilina, polen'),
        _field(flow, 'conditions', 'Enfermedades previas',
            flow.previousConditions, (value) => flow.previousConditions = value,
            hint: 'Diabetes, hipertensión'),
        _field(flow, 'family', 'Antecedentes oculares familiares',
            flow.familyHistory, (value) => flow.familyHistory = value,
            hint: 'Glaucoma en la madre, miopía alta en el padre…',
            maxLength: 1000,
            lines: 3),
        SolidButton(
            label: 'Guardar antecedentes',
            loading: flow.saving,
            icon: Icons.chevron_right,
            onPressed: () async {
              await flow.saveHistory();
            }),
      ];

  List<Widget> _prescription(ClinicalCareFlow flow) {
    final form = flow.prescription;
    final locked = flow.prescriptionSaved;
    Widget number(
            String key, String label, String value, ValueChanged<String> update,
            {bool axis = false}) =>
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _field(flow, key, label, value, update,
                    numeric: true,
                    axis: axis,
                    maxLength: axis ? 3 : 6,
                    readOnly: locked)));
    return [
      _title('Receta óptica',
          'Esfera y cilindro en dioptrías (ej. -1.75); eje en grados de 0 a 180.'),
      if (locked)
        const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
                'La receta ya está guardada. Reintenta para cerrar la cita.')),
      AppCard(
          child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 16), child: Text('OD')),
          number('sphereOD', 'Esfera', form.sphereOD, (v) => form.sphereOD = v),
          number('cylinderOD', 'Cilindro', form.cylinderOD,
              (v) => form.cylinderOD = v),
          number('axisOD', 'Eje', form.axisOD, (v) => form.axisOD = v,
              axis: true)
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 16), child: Text('OI')),
          number('sphereOS', 'Esfera', form.sphereOS, (v) => form.sphereOS = v),
          number('cylinderOS', 'Cilindro', form.cylinderOS,
              (v) => form.cylinderOS = v),
          number('axisOS', 'Eje', form.axisOS, (v) => form.axisOS = v,
              axis: true)
        ]),
      ])),
      const SizedBox(height: 16),
      _field(flow, 'addition', 'Adición (cerca) · opcional 0 a 4',
          form.addition, (v) => form.addition = v,
          numeric: true, maxLength: 6, readOnly: locked),
      _field(flow, 'treatment', 'Tratamiento · opcional', form.treatment,
          (v) => form.treatment = v,
          hint: 'Antirreflejo, filtro de luz azul',
          maxLength: 255,
          readOnly: locked),
      _field(flow, 'frame', 'Tipo de montura recomendada · opcional',
          form.recommendedFrameType, (v) => form.recommendedFrameType = v,
          hint: 'Completa de acetato', maxLength: 255, readOnly: locked),
      SolidButton(
          label: locked
              ? 'Reintentar cierre de cita'
              : 'Guardar receta y finalizar',
          loading: flow.saving,
          icon: Icons.check,
          onPressed: () async {
            await flow.savePrescriptionAndFinish();
          }),
      if (!locked) ...[
        const SizedBox(height: 10),
        SolidButton(
            label: 'Volver a antecedentes',
            background: AppColors.white,
            foreground: AppColors.staffInk,
            border: AppColors.staffBorder,
            onPressed: flow.saving ? null : flow.back)
      ],
    ];
  }

  List<Widget> _done(ClinicalCareFlow flow) => [
        AppCard(
            child: Column(children: [
          const Icon(Icons.check_circle, color: AppColors.emerald600, size: 48),
          const SizedBox(height: 12),
          const Text('Atención finalizada',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
              'La ficha clínica y la receta quedaron guardadas y la cita figura como completada.',
              textAlign: TextAlign.center)
        ])),
        const SizedBox(height: 18),
        SolidButton(
            label: 'Ver ficha del paciente',
            icon: Icons.person_outline,
            onPressed: () => context
                .replace('/s/patient/${Uri.encodeComponent(flow.patientId)}')),
        const SizedBox(height: 10),
        SolidButton(
            label: 'Volver a la agenda',
            background: AppColors.white,
            foreground: AppColors.staffInk,
            border: AppColors.staffBorder,
            onPressed: () => context.go('/s/agenda')),
      ];
}
