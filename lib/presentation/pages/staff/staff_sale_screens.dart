import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/commerce.dart';
import '../../../domain/entities/store_time.dart';
import '../../state/optiflow_controller.dart';
import '../../state/quote_flow.dart';
import '../../state/sale_flow.dart';
import '../../widgets/chrome.dart';
import 'staff_commerce_widgets.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key, this.patientId});
  final String? patientId;
  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}
class _QuoteScreenState extends State<QuoteScreen> {
  bool get hasPatient => widget.patientId?.isNotEmpty == true;
  @override
  void initState() { super.initState(); _scheduleLoad(); }
  @override
  void didUpdateWidget(covariant QuoteScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.patientId != widget.patientId) _scheduleLoad(); }
  void _scheduleLoad() => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && hasPatient) context.read<OptiFlowController>().startQuote(widget.patientId!); });
  @override
  Widget build(BuildContext context) {
    if (!hasPatient) return const CommercePatientPicker(sales: false);
    final app = context.watch<OptiFlowController>();
    final flow = app.quoteFlow?.patientId == widget.patientId ? app.quoteFlow : null;
    final quotation = flow?.quotation;
    return PopScope(canPop: flow?.saving != true, child: StaffScaffold(tab: null, showBottomBar: false,
      topBar: StaffTopBar(title: quotation == null ? 'Nueva cotización' : 'Cotización', onBack: () { if (flow?.saving != true) commerceBack(context); }),
      body: flow == null ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        CommercePatientCard(flow.patient, caption: flow.record == null ? null : [
          flow.record!.examinationDate == null ? 'Receta vigente' : 'Receta del ${DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(flow.record!.examinationDate!))}',
          if (flow.record!.prescription?.treatment?.isNotEmpty == true) flow.record!.prescription!.treatment!,
        ].join(' · ')),
        const SizedBox(height: 20),
        if (flow.loading) const LinearProgressIndicator()
        else if (flow.loadError != null) ...[
          CommerceNotice(flow.loadError!), SolidButton(label: 'Reintentar', onPressed: flow.load),
          TextButton(onPressed: () => context.push('/s/patient/${Uri.encodeComponent(widget.patientId!)}'), child: const Text('Ver ficha del paciente')),
        ] else ...[
          if (quotation == null) ..._builder(flow) else ..._detail(flow, quotation),
          if (flow.error != null) CommerceNotice(flow.error!),
        ],
      ]),
    ));
  }
  List<Widget> _builder(QuoteFlow flow) => [
    if (flow.lastRejectedReason != null) CommerceNotice('La cotización anterior fue rechazada: ${flow.lastRejectedReason}'),
    const SectionHeader('Montura'), const SizedBox(height: 10),
    if (flow.catalogWarning != null) CommerceNotice(flow.catalogWarning!),
    if (flow.stockWarning != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Stock sin confirmar: ${flow.stockWarning}', style: const TextStyle(fontSize: 11, color: AppColors.slate400))),
    if (flow.frames.isEmpty && flow.catalogWarning == null) const Text('No hay monturas en el catálogo.'),
    for (final frame in flow.frames) Padding(padding: const EdgeInsets.only(bottom: 8), child: AppCard(
      borderColor: frame.sku == flow.frameSku ? AppColors.staffAccent : null,
      onTap: flow.saving ? null : () => flow.selectFrame(frame.sku),
      child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(frame.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text('${frame.description} · ${frame.sku}', style: const TextStyle(fontSize: 11)),
        Text(flow.stock[frame.sku] == null ? 'Stock sin confirmar' : flow.stock[frame.sku] == 0 ? 'Sin stock en esta óptica' : '${flow.stock[frame.sku]} en esta óptica', style: TextStyle(fontSize: 11, color: flow.stock[frame.sku] == 0 ? AppColors.errorRed : AppColors.staffAccent)),
      ])), const SizedBox(width: 10), Text(soles(frame.price)), if (frame.sku == flow.frameSku) const Icon(Icons.check, color: AppColors.staffAccent)],),
    )),
    const SizedBox(height: 16), const SectionHeader('Lentes'), const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: [for (final entry in lensOptions.indexed) FilterChip(label: Text(entry.$2.name), selected: flow.lensIndex == entry.$1, onSelected: flow.saving ? null : (_) => flow.selectLens(entry.$1))]),
    if (flow.lensIndex != null) ...[const SizedBox(height: 10), TextFormField(key: ValueKey('lens-${flow.lensIndex}'), initialValue: flow.lensPrice, enabled: !flow.saving, decoration: const InputDecoration(labelText: 'Precio de los lentes (S/)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) { flow.lensPrice = v; flow.changed(); })],
    const SizedBox(height: 20), const SectionHeader('Tratamientos'), const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: [for (final option in treatmentOptions) FilterChip(label: Text('${option.name} · ${soles(option.price)}'), selected: flow.treatments.contains(option.name), onSelected: flow.saving ? null : (_) => flow.toggleTreatment(option.name))]),
    const SizedBox(height: 18), CommerceSummary(items: flow.draftItems), const SizedBox(height: 20),
    SolidButton(label: 'Generar cotización', loading: flow.saving, onPressed: flow.generate),
  ];
  List<Widget> _detail(QuoteFlow flow, Quotation quote) => [
    Row(children: [const Expanded(child: SectionHeader('Productos')), Chip(label: Text(switch (quote.status) { QuotationStatus.draft => 'Borrador', QuotationStatus.approved => 'Aprobada', QuotationStatus.rejected => 'Rechazada' }))]),
    const SizedBox(height: 10), CommerceSummary(items: quote.items, quotation: quote), const SizedBox(height: 20),
    if (quote.status == QuotationStatus.approved) ...[
      CommerceNotice(flow.sale == null ? 'El paciente aceptó la cotización. Ya se puede registrar la venta.' : 'La venta de esta cotización ya está registrada.', success: true),
      SolidButton(label: flow.sale == null ? 'Registrar venta' : 'Ver venta', loading: flow.saving, icon: Icons.credit_card, onPressed: () async {
        final sale = await flow.startSale();
        if (!mounted || sale == null) return;
        await context.push(commerceRoute('/s/sale', flow.patientId, saleId: sale.id));
      }),
    ] else if (quote.status == QuotationStatus.draft) ...[
      const SectionHeader('Descuento o promoción'), const SizedBox(height: 10),
      Wrap(spacing: 8, children: [for (final percentage in [true, false]) ChoiceChip(label: Text(percentage ? 'Porcentaje' : 'Monto fijo (S/)'), selected: flow.discountIsPercentage == percentage, onSelected: flow.saving ? null : (_) => setState(() { flow.discountIsPercentage = percentage; flow.changed(); }))]),
      const SizedBox(height: 10), TextFormField(key: ValueKey('discount-${quote.id}'), initialValue: flow.discountValue, enabled: !flow.saving, decoration: InputDecoration(labelText: flow.discountIsPercentage ? 'Descuento (%)' : 'Descuento (S/)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) { flow.discountValue = v; flow.changed(); }),
      const SizedBox(height: 10), TextFormField(initialValue: flow.discountReason, enabled: !flow.saving, maxLength: 255, decoration: const InputDecoration(labelText: 'Motivo (opcional)'), onChanged: (v) { flow.discountReason = v; flow.changed(); }),
      SolidButton(label: 'Aplicar descuento', onPressed: flow.saving ? null : flow.applyDiscount, background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.lavender),
      const SizedBox(height: 24),
      if (flow.showReject) ...[
        TextFormField(initialValue: flow.rejectReason, enabled: !flow.saving, maxLength: 255, decoration: const InputDecoration(labelText: 'Motivo del rechazo'), onChanged: (v) { flow.rejectReason = v; flow.changed(); }),
        SolidButton(label: 'Rechazar', loading: flow.saving, onPressed: flow.reject, background: AppColors.errorRed),
        TextButton(onPressed: flow.saving ? null : () => setState(() => flow.showReject = false), child: const Text('Cancelar')),
      ] else ...[
        SolidButton(label: 'Aprobar', loading: flow.saving, onPressed: flow.approve),
        TextButton(onPressed: flow.saving ? null : () => setState(() { flow.showReject = true; flow.rejectReason = ''; }), child: const Text('Rechazar', style: TextStyle(color: AppColors.errorRed))),
      ],
    ] else ...[CommerceNotice(quote.rejectionReason ?? 'La cotización fue rechazada.'), SolidButton(label: 'Preparar otra cotización', onPressed: flow.load)],
  ];
}

class ConfirmSaleScreen extends StatefulWidget {
  const ConfirmSaleScreen({super.key, this.patientId, this.saleId});
  final String? patientId, saleId;
  @override
  State<ConfirmSaleScreen> createState() => _ConfirmSaleScreenState();
}
class _ConfirmSaleScreenState extends State<ConfirmSaleScreen> {
  bool get hasPatient => widget.patientId?.isNotEmpty == true;
  @override
  void initState() { super.initState(); _scheduleLoad(); }
  @override
  void didUpdateWidget(covariant ConfirmSaleScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.patientId != widget.patientId || oldWidget.saleId != widget.saleId) _scheduleLoad(); }
  void _scheduleLoad() => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && hasPatient) context.read<OptiFlowController>().openStaffSale(widget.patientId!, saleId: widget.saleId); });
  @override
  Widget build(BuildContext context) {
    if (!hasPatient) return const CommercePatientPicker(sales: true);
    final app = context.watch<OptiFlowController>();
    final current = app.saleFlow;
    final flow = current?.patientId == widget.patientId && current?.saleId == widget.saleId ? current : null;
    final sale = flow?.sale;
    return PopScope(canPop: flow?.saving != true, child: StaffScaffold(tab: null, showBottomBar: false,
      topBar: StaffTopBar(title: sale?.status == SaleStatus.closed ? 'Venta confirmada' : widget.saleId == null ? 'Ventas y pagos' : 'Venta', onBack: () { if (flow?.saving != true) commerceBack(context); }),
      body: flow == null ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: flow.refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        CommercePatientCard(flow.patient), const SizedBox(height: 20),
        if (flow.loading) const LinearProgressIndicator()
        else if (flow.loadError != null) ...[CommerceNotice(flow.loadError!), SolidButton(label: 'Reintentar', onPressed: flow.refresh)]
        else if (widget.saleId == null) ..._sales(flow)
        else if (sale != null) ..._sale(flow, sale),
        if (flow.error != null) CommerceNotice(flow.error!), const SizedBox(height: 24),
      ])),
    ));
  }
  List<Widget> _sales(SaleFlow flow) => [
    if (flow.sales.isEmpty) const Text('Este paciente no tiene ventas registradas.'),
    for (final sale in flow.sales) Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(onTap: () => context.push(commerceRoute('/s/sale', flow.patientId, saleId: sale.id)).then((_) { if (mounted) context.read<OptiFlowController>().openStaffSale(widget.patientId!); }), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Venta #${sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
      CommercePair(saleStatusLabel(sale.status), sale.amount == null ? 'Ver detalle' : soles(sale.amount!)),
      if (sale.receiptNumber != null) Text('Boleta ${sale.receiptNumber}'),
    ]))),
    const SizedBox(height: 16), SolidButton(label: 'Nueva cotización', onPressed: () => context.push(commerceRoute('/s/quote', flow.patientId)).then((_) { if (mounted) context.read<OptiFlowController>().openStaffSale(widget.patientId!); })),
  ];
  List<Widget> _sale(SaleFlow flow, Sale sale) => [
    if (sale.status == SaleStatus.closed) ...[
      const Center(child: CircleAvatar(radius: 40, backgroundColor: AppColors.electric, child: Icon(Icons.check, size: 36, color: AppColors.white))), const SizedBox(height: 16),
      const Center(child: Text('Venta confirmada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      const CommerceNotice('Se emitió la boleta y se generó la orden de trabajo.', success: true),
      AppCard(child: Column(children: [CommercePair('Boleta', sale.receiptNumber ?? 'Sin número informado'), CommercePair('Total', soles(sale.amount ?? flow.quotation!.total)), CommercePair('Pago', paymentMethodLabel(sale.paymentMethod))])),
      const SizedBox(height: 24), SolidButton(label: 'Volver al inicio', onPressed: flow.saving ? null : () => context.go('/s/home')),
    ] else ...[
      const SectionHeader('Resumen'), const SizedBox(height: 12), CommerceSummary(items: flow.quotation!.items, quotation: flow.quotation), const SizedBox(height: 18),
      if (sale.status == SaleStatus.paid) ...[
        CommerceNotice('Pagada con ${paymentMethodLabel(sale.paymentMethod).toLowerCase()}. Cierra la venta para emitir la boleta.', success: true),
        SolidButton(label: 'Cerrar venta y emitir boleta', loading: flow.saving, onPressed: flow.closePaidSale),
      ] else ...[
        if (sale.paymentStatus == 'REJECTED') const CommerceNotice('El último pago con tarjeta o Yape fue rechazado.'),
        const Text('Pendiente de pago', style: TextStyle(color: AppColors.staffAccent)), const SizedBox(height: 12),
        SolidButton(label: 'Cobrar ${soles(flow.quotation!.total)} en efectivo', loading: flow.saving, onPressed: flow.payCashAndClose, icon: Icons.credit_card), const SizedBox(height: 12),
        const Text('Para pagar con tarjeta o Yape, el paciente entra a Mis compras en su app y toca Pagar.', style: TextStyle(fontSize: 11, color: AppColors.slate400)),
      ],
      const SizedBox(height: 12), SolidButton(label: 'Actualizar estado del pago', onPressed: flow.saving ? null : flow.refresh, background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.lavender),
    ],
  ];
}
