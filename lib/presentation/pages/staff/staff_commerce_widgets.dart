import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/commerce.dart';
import '../../../domain/entities/staff_patient.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

String commerceRoute(String path, String patientId, {String? saleId}) => Uri(path: path, queryParameters: {'patientId': patientId, if (saleId != null) 'saleId': saleId}).toString();
void commerceBack(BuildContext context) => context.canPop() ? context.pop() : context.go('/s/home');

class CommerceNotice extends StatelessWidget {
  const CommerceNotice(this.text, {super.key, this.success = false});
  final String text;
  final bool success;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: AppCard(color: success ? const Color(0xFFECFDF5) : AppColors.errorBg, child: Text(text, style: TextStyle(color: success ? const Color(0xFF047857) : AppColors.errorRed))));
}

class CommercePatientCard extends StatelessWidget {
  const CommercePatientCard(this.patient, {super.key, this.caption});
  final StaffPatient? patient;
  final String? caption;
  @override
  Widget build(BuildContext context) => AppCard(color: AppColors.staffBlue50, child: Row(children: [
    CircleAvatar(backgroundColor: AppColors.lavender, child: Text(patient?.initials ?? '-')),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Paciente', style: TextStyle(fontSize: 10)), Text(patient?.fullName ?? 'Cargando paciente', style: const TextStyle(fontWeight: FontWeight.bold)),
      if (caption?.isNotEmpty == true) Text(caption!, style: const TextStyle(fontSize: 11, color: AppColors.staffAccent)),
    ])),
  ]));
}

class CommercePair extends StatelessWidget {
  const CommercePair(this.label, this.value, {super.key, this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.bold : FontWeight.normal))), const SizedBox(width: 12), Text(value, style: TextStyle(fontWeight: strong ? FontWeight.bold : FontWeight.normal))]));
}

class CommerceSummary extends StatelessWidget {
  const CommerceSummary({super.key, required this.items, this.quotation});
  final List<QuotationItem> items;
  final Quotation? quotation;
  @override
  Widget build(BuildContext context) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (items.isEmpty) const CommercePair('Sin productos', '-'),
    for (final item in items) CommercePair('${item.description}${item.quantity > 1 ? ' ×${item.quantity}' : ''}', soles(item.subtotal)),
    const Divider(color: AppColors.lavender),
    CommercePair('Subtotal', soles(quotation?.subtotal ?? items.fold<num>(0, (sum, item) => sum + item.subtotal))),
    if (quotation?.discount case final discount?) ...[
      CommercePair('Descuento${discount.type == 'PERCENTAGE' ? ' (${discount.value} %)' : ''}', '-${soles(discount.amount)}'),
      if (discount.reason != null) Text(discount.reason!, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
    ],
    if (quotation != null) CommercePair('Total', soles(quotation!.total), strong: true),
  ]));
}

class CommercePatientPicker extends StatefulWidget {
  const CommercePatientPicker({super.key, required this.sales});
  final bool sales;
  @override
  State<CommercePatientPicker> createState() => _CommercePatientPickerState();
}
class _CommercePatientPickerState extends State<CommercePatientPicker> {
  String query = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) context.read<OptiFlowController>().refreshStaffPatients(); });
  }
  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final search = query.trim().toLowerCase();
    final patients = app.staffPatients.where((p) => '${p.fullName} ${p.email} ${p.phone}'.toLowerCase().contains(search));
    return StaffScaffold(tab: null, showBottomBar: false,
      topBar: StaffTopBar(title: widget.sales ? 'Ventas y pagos' : 'Nueva cotización', onBack: () => commerceBack(context)),
      body: RefreshIndicator(onRefresh: app.refreshStaffPatients, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        Text(widget.sales ? 'Elige al paciente para consultar sus ventas.' : '¿Para qué paciente es la cotización?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (!widget.sales) const Text('Se usa su última receta.'),
        const SizedBox(height: 14), TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Nombre, correo o teléfono'), onChanged: (v) => setState(() => query = v)),
        const SizedBox(height: 14),
        if (app.staffPatientsLoading) const LinearProgressIndicator(),
        if (app.staffPatientsError != null) ...[CommerceNotice(app.staffPatientsError!), TextButton(onPressed: app.refreshStaffPatients, child: const Text('Reintentar'))]
        else if (!app.staffPatientsLoading && patients.isEmpty) const Text('No hay pacientes que coincidan.'),
        for (final patient in patients) Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(onTap: () => context.push(commerceRoute(widget.sales ? '/s/sale' : '/s/quote', patient.id)), child: Row(children: [
          CircleAvatar(child: Text(patient.initials)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient.fullName), Text(patient.email.isEmpty ? patient.phone : patient.email, style: const TextStyle(fontSize: 11))])), const Icon(Icons.chevron_right),
        ]))),
      ])),
    );
  }
}
