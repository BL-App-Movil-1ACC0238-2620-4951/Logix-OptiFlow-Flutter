import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/clinical/presentation/quote_view_model.dart';
import 'package:logix_optiflow/features/clinical/presentation/sale_view_model.dart';
import 'package:logix_optiflow/features/clinical/presentation/quote_flow.dart';
import 'package:logix_optiflow/features/clinical/presentation/sale_flow.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';
import 'package:logix_optiflow/presentation/pages/staff/staff_commerce_widgets.dart';

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

  void _scheduleLoad() => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && hasPatient) getIt<QuoteViewModel>().start(widget.patientId!); });

  @override
  Widget build(BuildContext context) {
    if (!hasPatient) return const CommercePatientPicker(sales: false);
    final quoteVm = getIt<QuoteViewModel>();
    return ListenableBuilder(
      listenable: quoteVm,
      builder: (context, _) {
        final flow = quoteVm.flow?.patientId == widget.patientId ? quoteVm.flow : null;
        final quotation = flow?.quotation;
        return PopScope(
          canPop: flow?.saving != true,
          child: StaffScaffold(
            tab: null,
            showBottomBar: false,
            topBar: StaffTopBar(title: quotation == null ? 'Nueva cotización' : 'Cotización', onBack: () { if (flow?.saving != true) commerceBack(context); }),
            body: flow == null
                ? const _Loading()
                : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
                    CommercePatientCard(flow.patient, caption: flow.record == null ? null : [
                      flow.record!.examinationDate == null ? 'Receta vigente' : 'Receta del ${DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(flow.record!.examinationDate!))}',
                      if (flow.record!.prescription?.treatment?.isNotEmpty == true) flow.record!.prescription!.treatment!,
                    ].join(' · ')),
                    const SizedBox(height: 20),
                    if (flow.loading)
                      const _Loading()
                    else if (flow.loadError != null) ...[
                      CommerceNotice(flow.loadError!),
                      const SizedBox(height: 16),
                      StaffButton(label: 'Ver ficha del paciente', onPressed: () => context.push('/s/patient/${Uri.encodeComponent(widget.patientId!)}')),
                      const SizedBox(height: 10),
                      StaffButton(label: 'Reintentar', icon: LucideIcons.refreshCw, background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: flow.load),
                    ] else ...[
                      if (quotation == null) ..._builder(flow) else ..._detail(flow, quotation),
                      if (flow.error != null) ...[const SizedBox(height: 12), CommerceNotice(flow.error!)],
                    ],
                  ]),
          ),
        );
      },
    );
  }

  List<Widget> _builder(QuoteFlow flow) {
    final enabled = !flow.saving;
    return [
      if (flow.lastRejectedReason != null) ...[
        CommerceNotice('La cotización anterior fue rechazada: ${flow.lastRejectedReason}'),
        const SizedBox(height: 16),
      ],
      const CommerceHeading('Montura'),
      const SizedBox(height: 10),
      if (flow.catalogWarning != null) ...[CommerceNotice(flow.catalogWarning!), const SizedBox(height: 10)],
      if (flow.stockWarning != null)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Stock sin confirmar: ${flow.stockWarning}', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400))),
      if (flow.frames.isEmpty && flow.catalogWarning == null)
        Text('No se pudo cargar el catálogo de monturas.', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
      for (final frame in flow.frames)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Builder(builder: (context) {
            final selected = frame.sku == flow.frameSku;
            final units = flow.stock[frame.sku];
            return CommerceCard(
              border: selected ? AppColors.staffAccent : AppColors.staffBorder,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: enabled ? () => flow.selectFrame(frame.sku) : null,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(frame.name, style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                    Text([if (frame.description.isNotEmpty) frame.description, frame.sku].join(' · '), style: AppFonts.inter(fontSize: 10, color: AppColors.slate400)),
                    if (units != null)
                      Text(units == 0 ? 'Sin stock en esta óptica' : '$units en esta óptica', style: AppFonts.inter(fontSize: 10, color: units == 0 ? AppColors.errorRed : AppColors.emerald700)),
                  ]),
                ),
                Text(soles(frame.price), style: AppFonts.inter(fontSize: 12, color: selected ? AppColors.staffAccent : AppColors.staffInk)),
                if (selected) ...[const SizedBox(width: 8), const Icon(LucideIcons.check, size: 18, color: AppColors.staffAccent)],
              ]),
            );
          }),
        ),
      const SizedBox(height: 16),
      const CommerceHeading('Lentes'),
      const SizedBox(height: 10),
      _ChipRows(
        labels: [for (final o in lensOptions) o.name],
        selected: (i) => flow.lensIndex == i,
        onTap: (i) { if (enabled) flow.selectLens(i); },
      ),
      if (flow.lensIndex != null) ...[
        const SizedBox(height: 10),
        const StaffLabel('Precio de los lentes (S/)'),
        const SizedBox(height: 6),
        CommerceField(
          key: ValueKey('lens-${flow.lensIndex}'),
          initialValue: flow.lensPrice,
          placeholder: '0.00',
          decimal: true,
          enabled: enabled,
          onChanged: (v) { flow.lensPrice = v; flow.changed(); },
        ),
      ],
      const SizedBox(height: 16),
      const CommerceHeading('Tratamientos'),
      const SizedBox(height: 10),
      _ChipRows(
        labels: [for (final o in treatmentOptions) '${o.name} · ${soles(o.price)}'],
        selected: (i) => flow.treatments.contains(treatmentOptions[i].name),
        onTap: (i) { if (enabled) flow.toggleTreatment(treatmentOptions[i].name); },
      ),
      const SizedBox(height: 18),
      CommerceSummary(items: flow.draftItems),
      const SizedBox(height: 20),
      StaffButton(label: flow.saving ? 'Generando...' : 'Generar cotización', onPressed: enabled ? flow.generate : null),
    ];
  }

  List<Widget> _detail(QuoteFlow flow, Quotation quote) {
    final enabled = !flow.saving;
    final (badge, badgeColor, badgeBackground) = switch (quote.status) {
      QuotationStatus.draft => ('Borrador', AppColors.staffAccent, commerceSoft),
      QuotationStatus.approved => ('Aprobada', AppColors.emerald700, AppColors.emerald50),
      QuotationStatus.rejected => ('Rechazada', AppColors.errorRed, AppColors.errorBg),
    };
    return [
      Row(children: [
        const Expanded(child: CommerceHeading('Productos')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeBackground, borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: AppFonts.inter(fontSize: 10, color: badgeColor)),
        ),
      ]),
      const SizedBox(height: 10),
      CommerceSummary(items: quote.items, quotation: quote),
      const SizedBox(height: 20),
      if (quote.status == QuotationStatus.approved) ...[
        CommerceNotice(flow.sale == null ? 'El paciente aceptó la cotización. Ya se puede registrar la venta.' : 'La venta de esta cotización ya está registrada.', success: true),
        const SizedBox(height: 16),
        StaffButton(
          label: flow.saving ? 'Registrando...' : flow.sale == null ? 'Registrar venta' : 'Ver venta',
          icon: LucideIcons.creditCard,
          onPressed: enabled
              ? () async {
                  final sale = await flow.startSale();
                  if (!mounted || sale == null) return;
                  await context.push(commerceRoute('/s/sale', flow.patientId, saleId: sale.id));
                }
              : null,
        ),
      ] else if (quote.status == QuotationStatus.draft) ...[
        const CommerceHeading('Descuento o promoción'),
        const SizedBox(height: 10),
        Row(children: [
          StaffChip('Porcentaje', selected: flow.discountIsPercentage, onTap: () { if (enabled) setState(() { flow.discountIsPercentage = true; flow.changed(); }); }),
          const SizedBox(width: 8),
          StaffChip('Monto fijo (S/)', selected: !flow.discountIsPercentage, onTap: () { if (enabled) setState(() { flow.discountIsPercentage = false; flow.changed(); }); }),
        ]),
        const SizedBox(height: 10),
        CommerceField(
          key: ValueKey('discount-${quote.id}'),
          initialValue: flow.discountValue,
          placeholder: flow.discountIsPercentage ? 'Ej. 10' : 'Ej. 50.00',
          decimal: true,
          enabled: enabled,
          onChanged: (v) { flow.discountValue = v; flow.changed(); },
        ),
        const SizedBox(height: 8),
        CommerceField(
          key: ValueKey('reason-${quote.id}'),
          initialValue: flow.discountReason,
          placeholder: 'Motivo (opcional), ej. Campaña escolar',
          maxLength: 255,
          enabled: enabled,
          onChanged: (v) { flow.discountReason = v; flow.changed(); },
        ),
        const SizedBox(height: 10),
        StaffButton(label: 'Aplicar descuento', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: enabled ? flow.applyDiscount : null),
        const SizedBox(height: 24),
        if (flow.showReject) ...[
          const StaffLabel('Motivo del rechazo'),
          const SizedBox(height: 6),
          CommerceField(
            key: ValueKey('reject-${quote.id}'),
            initialValue: flow.rejectReason,
            placeholder: 'Ej. El paciente lo pensará',
            maxLength: 255,
            enabled: enabled,
            onChanged: (v) { flow.rejectReason = v; flow.changed(); },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: StaffButton(label: 'Cancelar', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: enabled ? () => setState(() => flow.showReject = false) : null)),
            const SizedBox(width: 10),
            Expanded(child: StaffButton(label: flow.saving ? 'Guardando...' : 'Rechazar', background: AppColors.errorRed, onPressed: enabled ? flow.reject : null)),
          ]),
        ] else
          Row(children: [
            Expanded(
              child: StaffButton(
                label: 'Rechazar',
                background: AppColors.white,
                foreground: AppColors.errorRed,
                border: AppColors.staffBorder,
                onPressed: enabled ? () => setState(() { flow.showReject = true; flow.rejectReason = ''; }) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: StaffButton(label: flow.saving ? 'Guardando...' : 'Aprobar', onPressed: enabled ? flow.approve : null)),
          ]),
      ] else ...[
        CommerceNotice(quote.rejectionReason ?? 'La cotización fue rechazada.'),
        const SizedBox(height: 16),
        StaffButton(label: 'Preparar otra cotización', onPressed: enabled ? flow.load : null),
      ],
    ];
  }
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

  void _scheduleLoad() => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && hasPatient) getIt<SaleViewModel>().open(widget.patientId!, saleId: widget.saleId); });

  @override
  Widget build(BuildContext context) {
    if (!hasPatient) return const CommercePatientPicker(sales: true);
    final saleVm = getIt<SaleViewModel>();
    return ListenableBuilder(
      listenable: saleVm,
      builder: (context, _) {
        final current = saleVm.flow;
        final flow = current?.patientId == widget.patientId && current?.saleId == widget.saleId ? current : null;
        final sale = flow?.sale;
        return PopScope(
          canPop: flow?.saving != true,
          child: StaffScaffold(
            tab: null,
            showBottomBar: false,
            topBar: StaffTopBar(
              title: sale?.status == SaleStatus.closed ? 'Venta confirmada' : widget.saleId == null ? 'Ventas y pagos' : 'Venta',
              onBack: () { if (flow?.saving != true) commerceBack(context); },
            ),
            body: flow == null
                ? const _Loading()
                : RefreshIndicator(
                    onRefresh: flow.refresh,
                    child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
                      CommercePatientCard(flow.patient),
                      const SizedBox(height: 20),
                      if (flow.loading)
                        const _Loading()
                      else if (flow.loadError != null) ...[
                        CommerceNotice(flow.loadError!),
                        const SizedBox(height: 16),
                        StaffButton(label: 'Reintentar', onPressed: flow.refresh),
                      ] else if (widget.saleId == null)
                        ..._sales(flow)
                      else if (sale != null)
                        ..._sale(flow, sale),
                      if (flow.error != null) ...[const SizedBox(height: 12), CommerceNotice(flow.error!)],
                    ]),
                  ),
          ),
        );
      },
    );
  }

  List<Widget> _sales(SaleFlow flow) => [
        if (flow.sales.isEmpty) Text('Este paciente no tiene ventas registradas.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
        for (final sale in flow.sales)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CommerceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push(commerceRoute('/s/sale', flow.patientId, saleId: sale.id)).then((_) { if (mounted) getIt<SaleViewModel>().open(widget.patientId!); }),
              child: Row(children: [
                const StaffIconTile(LucideIcons.fileText, size: 36, background: commerceSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    StaffPill(saleStatusLabel(sale.status), icon: LucideIcons.clock),
                    const SizedBox(height: 4),
                    Text(
                      [sale.receiptNumber == null ? 'Venta #${sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase()}' : 'Boleta ${sale.receiptNumber}', if (sale.amount != null) soles(sale.amount!)].join(' · '),
                      style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk),
                    ),
                  ]),
                ),
                const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
              ]),
            ),
          ),
        const SizedBox(height: 16),
        StaffButton(
          label: 'Nueva cotización',
          icon: LucideIcons.fileText,
          onPressed: () => context.push(commerceRoute('/s/quote', flow.patientId)).then((_) { if (mounted) getIt<SaleViewModel>().open(widget.patientId!); }),
        ),
      ];

  List<Widget> _sale(SaleFlow flow, Sale sale) {
    final total = flow.quotation?.total;
    if (sale.status == SaleStatus.closed) {
      return [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, size: 34, color: AppColors.white),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text('Venta confirmada', style: AppFonts.inter(fontSize: 22, color: AppColors.staffInk))),
        const SizedBox(height: 6),
        Center(child: Text('Se emitió la boleta y se generó la orden de trabajo.', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400))),
        const SizedBox(height: 20),
        CommerceCard(
          radius: 20,
          border: AppColors.lavender,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            KeyValueRow('Boleta', sale.receiptNumber ?? '—'),
            const Divider(color: AppColors.lavender, height: 1),
            KeyValueRow('Total', soles(sale.amount ?? total ?? 0)),
            const Divider(color: AppColors.lavender, height: 1),
            KeyValueRow('Pago', paymentMethodLabel(sale.paymentMethod)),
          ]),
        ),
        const SizedBox(height: 24),
        StaffButton(label: 'Volver al inicio', onPressed: flow.saving ? null : () => context.go('/s/home')),
      ];
    }
    final quote = flow.quotation;
    return [
      const CommerceHeading('Resumen'),
      const SizedBox(height: 10),
      CommerceCard(
        child: Column(children: [
          for (final item in quote?.items ?? const <QuotationItem>[]) KeyValueRow(item.description, soles(item.subtotal)),
          if (quote?.discount case final discount?) KeyValueRow('Descuento', '-${soles(discount.amount)}'),
          const Divider(color: AppColors.lavender, thickness: 2, height: 2),
          CommerceTotal('Total', total == null ? '—' : soles(total)),
        ]),
      ),
      const SizedBox(height: 18),
      if (sale.status == SaleStatus.paid) ...[
        CommerceNotice('Pagada con ${paymentMethodLabel(sale.paymentMethod).toLowerCase()}. Cierra la venta para emitir la boleta.', success: true),
        const SizedBox(height: 16),
        StaffButton(label: flow.saving ? 'Cerrando...' : 'Cerrar venta y emitir boleta', onPressed: flow.saving ? null : flow.closePaidSale),
      ] else ...[
        if (sale.paymentStatus == 'REJECTED') ...[
          const CommerceNotice('El último pago con tarjeta o Yape fue rechazado.'),
          const SizedBox(height: 12),
        ],
        Text('Pendiente de pago', style: AppFonts.inter(fontSize: 13, color: AppColors.staffAccent)),
        const SizedBox(height: 12),
        StaffButton(
          label: flow.saving ? 'Registrando...' : 'Cobrar ${total == null ? '' : soles(total)} en efectivo',
          icon: LucideIcons.creditCard,
          onPressed: flow.saving ? null : flow.payCashAndClose,
        ),
        const SizedBox(height: 12),
        Text('Para pagar con tarjeta o Yape, el paciente entra a Mis compras en su app y toca Pagar.', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
        const SizedBox(height: 12),
        StaffButton(label: 'Actualizar estado del pago', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: flow.saving ? null : flow.refresh),
      ],
    ];
  }
}

/// Chips en filas de 2, como en Kotlin.
class _ChipRows extends StatelessWidget {
  const _ChipRows({required this.labels, required this.selected, required this.onTap});
  final List<String> labels;
  final bool Function(int) selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var row = 0; row < labels.length; row += 2)
        Padding(
          padding: EdgeInsets.only(bottom: row + 2 < labels.length ? 8 : 0),
          child: Row(children: [
            for (var i = row; i < row + 2 && i < labels.length; i++) ...[
              if (i > row) const SizedBox(width: 8),
              StaffChip(labels[i], selected: selected(i), onTap: () => onTap(i)),
            ],
          ]),
        ),
    ]);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text('Cargando...', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
      );
}
