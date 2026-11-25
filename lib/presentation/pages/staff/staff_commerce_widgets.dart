import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';
import 'package:logix_optiflow/presentation/pages/patient/search_screen.dart' show SearchField;
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

// Piezas comunes de cotización y venta, con el diseño de Kotlin (QuoteScreens.kt y SaleScreen.kt).

const commerceSoft = Color(0xFFF1F5FF);

String commerceRoute(String path, String patientId, {String? saleId}) => Uri(path: path, queryParameters: {'patientId': patientId, if (saleId != null) 'saleId': saleId}).toString();
void commerceBack(BuildContext context) => context.canPop() ? context.pop() : context.go('/s/home');

/// Aviso de color: rojo para errores y verde para confirmaciones.
class CommerceNotice extends StatelessWidget {
  const CommerceNotice(this.text, {super.key, this.success = false});
  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: success ? AppColors.emerald50 : AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: AppFonts.inter(fontSize: 12, color: success ? AppColors.emerald700 : AppColors.errorRed)),
    );
  }
}

class CommercePatientCard extends StatelessWidget {
  const CommercePatientCard(this.patient, {super.key, this.caption});
  final StaffPatient? patient;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: commerceSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        StaffInitials(patient?.initials ?? '—', size: 42, fontSize: 13),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Paciente', style: AppFonts.inter(fontSize: 9, color: AppColors.staffInk)),
            Text(patient?.fullName ?? 'Paciente', style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
            if (caption?.isNotEmpty == true) Text(caption!, style: AppFonts.inter(fontSize: 9, color: AppColors.staffAccent)),
          ]),
        ),
      ]),
    );
  }
}

/// Título de bloque: Inter 15 negrita.
class CommerceHeading extends StatelessWidget {
  const CommerceHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.staffInk));
}

/// Fila del total, más grande que las de los productos.
class CommerceTotal extends StatelessWidget {
  const CommerceTotal(this.label, this.value, {super.key, this.size = 16});
  final String label;
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Text(label, style: AppFonts.inter(fontSize: size, color: AppColors.staffInk))),
        Text(value, style: AppFonts.inter(fontSize: size, color: AppColors.staffInk)),
      ]),
    );
  }
}

class CommerceCard extends StatelessWidget {
  const CommerceCard({super.key, required this.child, this.onTap, this.border = AppColors.staffBorder, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8), this.radius = 18});
  final Widget child;
  final VoidCallback? onTap;
  final Color border;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => AppCard(onTap: onTap, radius: radius, borderColor: border, padding: padding, child: child);
}

/// Productos de la cotización con subtotal, descuento y total.
class CommerceSummary extends StatelessWidget {
  const CommerceSummary({super.key, required this.items, this.quotation});
  final List<QuotationItem> items;
  final Quotation? quotation;

  @override
  Widget build(BuildContext context) {
    final quote = quotation;
    final discount = quote?.discount;
    final subtotal = quote?.subtotal ?? items.fold<num>(0, (sum, item) => sum + item.subtotal);
    return CommerceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (items.isEmpty) const KeyValueRow('Sin productos', '—'),
        for (final item in items) KeyValueRow('${item.description}${item.quantity > 1 ? ' ×${item.quantity}' : ''}', soles(item.subtotal)),
        const Divider(color: AppColors.lavender, thickness: 2, height: 2),
        if (quote == null)
          CommerceTotal('Subtotal', soles(subtotal), size: 15)
        else ...[
          KeyValueRow('Subtotal', soles(subtotal)),
          if (discount != null) ...[
            KeyValueRow('Descuento (${discount.type == 'PERCENTAGE' ? '${_plain(discount.value)} %' : 'monto fijo'})', '-${soles(discount.amount)}'),
            if (discount.reason != null) Text(discount.reason!, style: AppFonts.inter(fontSize: 10, color: AppColors.slate400)),
          ],
          CommerceTotal('Total', soles(quote.total)),
        ],
      ]),
    );
  }

  static String _plain(num value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}

/// Campo con el estilo de `StaffInput` para valores que viven en el flujo (usa `initialValue`).
class CommerceField extends StatelessWidget {
  const CommerceField({
    super.key,
    required this.initialValue,
    required this.placeholder,
    required this.onChanged,
    this.enabled = true,
    this.decimal = false,
    this.maxLength,
  });

  final String initialValue;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool decimal;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.slate200));
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : null,
      inputFormatters: [if (maxLength != null) LengthLimitingTextInputFormatter(maxLength)],
      cursorColor: AppColors.staffAccent,
      style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.staffField,
        hintText: placeholder,
        hintStyle: AppFonts.inter(fontSize: 14, color: AppColors.slate400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.staffAccent)),
      ),
      onChanged: onChanged,
    );
  }
}

/// Paso previo: el asesor busca al paciente en el directorio.
class CommercePatientPicker extends StatefulWidget {
  const CommercePatientPicker({super.key, required this.sales});
  final bool sales;
  @override
  State<CommercePatientPicker> createState() => _CommercePatientPickerState();
}

class _CommercePatientPickerState extends State<CommercePatientPicker> {
  final _search = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<StaffPatientsViewModel>().refreshStaffPatients(); });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsVm = getIt<StaffPatientsViewModel>();
    return ListenableBuilder(
      listenable: patientsVm,
      builder: (context, _) {
        final search = query.trim().toLowerCase();
        final patients = patientsVm.state.patients.where((p) => '${p.fullName} ${p.email} ${p.phone}'.toLowerCase().contains(search)).toList();
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: widget.sales ? 'Ventas y pagos' : 'Nueva cotización', onBack: () => commerceBack(context)),
          body: RefreshIndicator(
            onRefresh: patientsVm.refreshStaffPatients,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                CommerceHeading(widget.sales ? 'Elige al paciente para consultar sus ventas.' : '¿Para qué paciente es la cotización?'),
                if (!widget.sales) ...[
                  const SizedBox(height: 4),
                  Text('Se usa su última receta.', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                ],
                const SizedBox(height: 14),
                SearchField(controller: _search, placeholder: 'Buscar por nombre, correo o teléfono', onChanged: (v) => setState(() => query = v)),
                const SizedBox(height: 14),
                if (patientsVm.state.loading && patientsVm.state.patients.isEmpty)
                  Text('Cargando pacientes...', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                if (patientsVm.state.error != null) ...[
                  CommerceNotice(patientsVm.state.error!),
                  TextButton(onPressed: patientsVm.refreshStaffPatients, child: const Text('Reintentar')),
                ] else if (!patientsVm.state.loading && patients.isEmpty)
                  Text('No hay pacientes que coincidan.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                for (final patient in patients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CommerceCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => context.push(commerceRoute(widget.sales ? '/s/sale' : '/s/quote', patient.id)),
                      child: Row(children: [
                        StaffInitials(patient.initials, size: 44, fontSize: 13),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(patient.fullName, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk)),
                            Text(patient.email.isEmpty ? patient.phone : patient.email, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
                          ]),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
