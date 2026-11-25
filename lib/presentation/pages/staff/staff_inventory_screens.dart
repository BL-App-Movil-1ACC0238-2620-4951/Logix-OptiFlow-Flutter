import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart' show soles;
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/inventory/presentation/new_frame_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/frame_photos.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

const _soft = Color(0xFFF1F5FF);
const _tile = Color(0xFFEEF2FF);
const _indigoText = Color(0xFF3F4FA8);

String _movementReason(StockMovement movement) => switch (movement.reason) {
      'REPLENISHMENT' => 'Reposición de proveedor',
      'SALE' => 'Venta',
      'ADJUSTMENT' => 'Ajuste',
      _ => movement.type == 'IN' ? 'Entrada' : 'Salida',
    };

/// "10 nov 2026, 17:20" en la hora de la óptica.
String _movementTime(DateTime value) => DateFormat('d MMM yyyy, HH:mm', 'es').format(StoreTime.clock(value)).replaceAll('.', '');

void _back(BuildContext context) => context.canPop() ? context.pop() : context.go('/s/inventory');

Widget _photo(String sku, {required double height, double? width, double radius = 14}) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(framePhotoFor(sku), height: height, width: width ?? double.infinity, fit: BoxFit.cover),
    );

Widget _muted(String text) => Text(text, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400));

/// Lista para elegir una opción, en lugar del selector que pasa a la siguiente de Kotlin.
Future<String?> _pick(BuildContext context, String title, List<(String, String)> options, String? selected) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          Text(title, style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 8),
          for (final (id, label) in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label, style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
              trailing: id == selected ? const Icon(LucideIcons.check, size: 18, color: AppColors.staffAccent) : null,
              onTap: () => Navigator.pop(sheetContext, id),
            ),
        ]),
      ),
    ),
  );
}

/// Detalle de una montura con su stock en la óptica (`/s/product/{sku}`), igual a Kotlin.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _price = TextEditingController();
  bool _editing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalogVm = getIt<CatalogViewModel>()..clearMutationError();
      catalogVm.loadFrame(widget.id, forInventory: true);
    });
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _edit(bool editing) {
    final frame = getIt<CatalogViewModel>().frameById(widget.id);
    getIt<CatalogViewModel>().clearMutationError();
    setState(() {
      _editing = editing;
      _message = null;
      _price.text = editing && frame != null ? frame.price.toStringAsFixed(2) : '';
    });
  }

  Future<void> _save() async {
    final catalogVm = getIt<CatalogViewModel>();
    final price = num.tryParse(_price.text.trim());
    final saved = await catalogVm.updateFramePrice(widget.id, price ?? 0);
    if (!mounted || !saved) return;
    final frame = catalogVm.frameById(widget.id);
    setState(() {
      _editing = false;
      _message = frame == null ? 'Precio actualizado.' : 'Precio actualizado a ${soles(frame.price)}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([catalogVm, sessionVm]),
      builder: (context, _) {
        final frame = catalogVm.frameById(widget.id);
        final product = catalogVm.productById(widget.id);
        final loadError = catalogVm.state.frameErrors[widget.id];
        final canStock = sessionVm.canOpen('/s/stock/${widget.id}');
        final canPrice = sessionVm.session?.role.can(StaffFeature.catalog) == true && !_editing;
        final quantity = product?.available ?? 0;
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Detalle del producto', onBack: () => _back(context)),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            if (frame == null || product == null) ...[
              if (loadError != null) ...[
                _muted(loadError),
                TextButton(onPressed: () => catalogVm.loadFrame(widget.id, forInventory: true), child: const Text('Reintentar')),
              ] else
                _muted('Cargando...'),
            ] else ...[
              AppCard(radius: 20, borderColor: AppColors.white, padding: const EdgeInsets.all(12), child: _photo(frame.sku, height: 200)),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: StaffPill(quantity == 0 ? 'Sin stock en tu óptica' : '$quantity unidades disponibles')),
              const SizedBox(height: 12),
              Text(frame.name, style: AppFonts.inter(fontSize: 22, color: AppColors.staffInk)),
              const SizedBox(height: 6),
              Text([frame.sku, frame.color, frame.material].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
              const SizedBox(height: 14),
              Text(soles(frame.price), style: AppFonts.inter(fontSize: 20, color: AppColors.staffInk)),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF7F9FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lavender)),
                child: Column(children: [
                  IntrinsicHeight(child: Row(children: [
                    _InfoCell('Material', frame.material ?? '—'),
                    const VerticalDivider(width: 1, color: AppColors.lavender),
                    _InfoCell('Forma', frame.shape ?? '—'),
                  ])),
                  const Divider(height: 1, color: AppColors.lavender),
                  IntrinsicHeight(child: Row(children: [
                    _InfoCell('Color', frame.color ?? '—'),
                    const VerticalDivider(width: 1, color: AppColors.lavender),
                    _InfoCell('Stock mínimo', product.minimumStock?.toString() ?? '—'),
                  ])),
                ]),
              ),
              if (_editing) ...[
                const SizedBox(height: 18),
                const StaffLabel('Nuevo precio (S/)'),
                const SizedBox(height: 8),
                StaffInput(
                  controller: _price,
                  placeholder: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(11)],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: StaffButton(label: 'Cancelar', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: () => _edit(false))),
                  const SizedBox(width: 12),
                  Expanded(child: StaffButton(label: catalogVm.state.mutationBusy ? 'Guardando...' : 'Guardar precio', onPressed: catalogVm.state.mutationBusy ? null : _save)),
                ]),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: AppFonts.inter(fontSize: 12, color: AppColors.staffGreen)),
              ],
              if (catalogVm.state.mutationError != null) ...[
                const SizedBox(height: 12),
                Text(catalogVm.state.mutationError!, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
              ],
              const SizedBox(height: 22),
              if (canStock || canPrice) ...[
                Row(children: [
                  if (canStock)
                    Expanded(
                      child: StaffButton(
                        label: 'Ver stock',
                        background: AppColors.white,
                        foreground: AppColors.staffInk,
                        border: AppColors.staffBorder,
                        onPressed: () => context.push('/s/stock/${Uri.encodeComponent(frame.sku)}'),
                      ),
                    ),
                  if (canStock && canPrice) const SizedBox(width: 12),
                  if (canPrice)
                    Expanded(child: StaffButton(label: 'Cambiar precio', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: () => _edit(true))),
                ]),
                const SizedBox(height: 12),
              ],
              if (sessionVm.canOpen('/s/quote')) StaffButton(label: 'Crear cotización', onPressed: () => context.push('/s/quote')),
            ],
          ]),
        );
      },
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppFonts.inter(fontSize: 9, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text(value, style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk)),
        ]),
      ),
    );
  }
}

/// Stock de una montura en la óptica y sus movimientos (`/s/stock/{sku}`), igual a Kotlin.
class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key, required this.id});
  final String id;
  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  DateTimeRange? range;

  Future<void> _refresh() async {
    final catalogVm = getIt<CatalogViewModel>();
    await Future.wait([
      catalogVm.loadFrame(widget.id, forInventory: true),
      catalogVm.refreshStockMovements(sku: widget.id, from: range?.start, to: range?.end),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getIt<StoreSearchViewModel>().loadStores();
      _refresh();
    });
  }

  Future<void> _changeRange() async {
    final selected = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now(), initialDateRange: range);
    if (selected == null || !mounted) return;
    setState(() => range = selected);
    await getIt<CatalogViewModel>().refreshStockMovements(sku: widget.id, from: selected.start, to: selected.end);
  }

  Future<void> _replenish() async {
    await context.push(Uri(path: '/s/movement', queryParameters: {'sku': widget.id}).toString());
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    final storesVm = getIt<StoreSearchViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([catalogVm, storesVm]),
      builder: (context, _) {
        final frame = catalogVm.frameById(widget.id);
        final product = catalogVm.productById(widget.id);
        final movements = catalogVm.state.movements.where((movement) => movement.sku == widget.id).toList();
        final period = range == null
            ? 'últimos 30 días'
            : '${DateFormat('dd/MM').format(range!.start)} – ${DateFormat('dd/MM').format(range!.end)}';
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Detalle y gestión de stock', onBack: () => _back(context)),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
              if (frame == null || product == null)
                _muted(catalogVm.state.frameErrors[widget.id] ?? 'Cargando...')
              else ...[
                _StockHero(storeName: storesVm.staffStoreName, frame: frame),
                const SizedBox(height: 12),
                _stats(product.available, product.minimumStock),
                const SizedBox(height: 24),
                StaffSectionTitle('Movimientos · $period', action: 'Cambiar fechas', onAction: _changeRange),
                const SizedBox(height: 12),
                if (catalogVm.state.movementsLoading)
                  _muted('Cargando...')
                else if (catalogVm.state.movementsError != null) ...[
                  Text(catalogVm.state.movementsError!, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
                  TextButton(onPressed: _refresh, child: const Text('Reintentar')),
                ] else if (movements.isEmpty)
                  _muted('Sin movimientos en este periodo.'),
                for (final movement in movements) ...[
                  _MovementRow(movement),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
                StaffButton(label: 'Registrar reposición', icon: LucideIcons.plus, onPressed: _replenish),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _stats(int stock, int? minimum) {
    final low = minimum != null && stock <= minimum;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _StockStat(
            icon: LucideIcons.box,
            tileBg: low ? AppColors.errorBg : _tile,
            tint: low ? AppColors.errorRed : AppColors.staffAccent,
            pill: low ? 'Bajo' : 'OK',
            value: '$stock',
            valueColor: low ? AppColors.errorRed : AppColors.staffInk,
            title: 'Stock actual',
            subtitle: 'Unidades en tu óptica',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StockStat(
            icon: LucideIcons.fileText,
            tileBg: _tile,
            tint: AppColors.staffAccent,
            pill: 'Mínimo',
            value: minimum?.toString() ?? '—',
            valueColor: AppColors.staffInk,
            title: 'Stock mínimo',
            subtitle: minimum == null
                ? 'Se fija en la primera reposición'
                : low
                    ? 'Faltan ${minimum - stock + 1} uds para salir de la alerta'
                    : '${stock - minimum} uds sobre el mínimo',
          ),
        ),
      ]),
    );
  }
}

class _StockHero extends StatelessWidget {
  const _StockHero({required this.storeName, required this.frame});
  final String storeName;
  final FrameItem frame;

  @override
  Widget build(BuildContext context) {
    final muted = AppFonts.inter(fontSize: 9, color: AppColors.slate300);
    final label = AppFonts.inter(fontSize: 7, color: AppColors.slate300);
    return StaffHero(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STOCK EN ${storeName.toUpperCase()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 8, color: AppColors.slate300)),
        const SizedBox(height: 14),
        Text(frame.name, style: AppFonts.inter(fontSize: 20, color: AppColors.white)),
        Text([frame.color, frame.material, frame.shape].whereType<String>().where((s) => s.isNotEmpty).join(' · '), style: muted),
        const SizedBox(height: 16),
        Row(children: [
          _photo(frame.sku, height: 44, width: 68, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SKU', style: label),
              Text(frame.sku, style: AppFonts.inter(fontSize: 16, color: AppColors.white)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('PRECIO', style: label),
            Text(soles(frame.price), style: AppFonts.inter(fontSize: 12, color: AppColors.white)),
          ]),
        ]),
      ]),
    );
  }
}

class _StockStat extends StatelessWidget {
  const _StockStat({
    required this.icon,
    required this.tileBg,
    required this.tint,
    required this.pill,
    required this.value,
    required this.valueColor,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color tileBg;
  final Color tint;
  final String pill;
  final String value;
  final Color valueColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      borderColor: AppColors.staffBorder,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StaffIconTile(icon, size: 32, background: tileBg, color: tint, radius: 10),
          const Spacer(),
          StaffPill(pill, size: 8),
        ]),
        const SizedBox(height: 16),
        Text(value, style: AppFonts.inter(fontSize: 24, color: valueColor)),
        Text(title, style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
        Text(subtitle, style: AppFonts.inter(fontSize: 8, color: AppColors.slate400)),
      ]),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow(this.movement);
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final entry = movement.type == 'IN';
    final units = '${movement.quantity} ud${movement.quantity == 1 ? '' : 's'}';
    return AppCard(
      radius: 18,
      borderColor: AppColors.staffBorder,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        StaffIconTile(entry ? LucideIcons.box : LucideIcons.creditCard, size: 32, background: _tile, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_movementReason(movement), style: AppFonts.inter(fontSize: 10, color: AppColors.staffInk)),
            Text(_movementTime(movement.createdAt), style: AppFonts.inter(fontSize: 7, color: AppColors.staffInk)),
          ]),
        ),
        Text('${entry ? '+' : '-'}$units', style: AppFonts.inter(fontSize: 11, color: entry ? AppColors.staffGreen : AppColors.errorRed)),
      ]),
    );
  }
}

/// Reposición de stock con el proveedor que entregó las monturas (`/s/movement`), igual a Kotlin.
class NewMovementScreen extends StatefulWidget {
  const NewMovementScreen({super.key, this.sku});
  final String? sku;
  @override
  State<NewMovementScreen> createState() => _NewMovementScreenState();
}

class _NewMovementScreenState extends State<NewMovementScreen> {
  String? selectedSku;
  String? supplierId;
  int quantity = 1;
  final minimum = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedSku = widget.sku;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalogVm = getIt<CatalogViewModel>();
      catalogVm.clearMutationError();
      catalogVm.refreshInventory();
      catalogVm.refreshSuppliers();
    });
  }

  @override
  void dispose() {
    minimum.dispose();
    super.dispose();
  }

  Future<void> _submit(String? sku, String? supplier) async {
    final catalogVm = getIt<CatalogViewModel>();
    if (catalogVm.state.mutationBusy) return;
    if (sku == null || supplier == null) {
      showAppMessage(context, 'Elige la montura y el proveedor.');
      return;
    }
    final saved = await catalogVm.replenishStock(sku: sku, supplierId: supplier, quantity: quantity, minimumStock: int.tryParse(minimum.text.trim()));
    if (!mounted || !saved) return;
    showAppMessage(context, 'Reposición registrada');
    _back(context);
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    return ListenableBuilder(
      listenable: catalogVm,
      builder: (context, _) {
        final state = catalogVm.state;
        final loading = state.inventoryLoading || state.suppliersLoading;
        final products = state.products;
        final suppliers = state.suppliers;
        final selected = products.where((p) => p.sku == selectedSku).firstOrNull ?? products.firstOrNull;
        final supplier = suppliers.where((s) => s.id == supplierId).firstOrNull ?? suppliers.firstOrNull;
        final current = selected?.available ?? 0;
        final error = state.mutationError ??
            state.inventoryError ??
            state.suppliersError ??
            (!loading && suppliers.isEmpty ? 'No hay proveedores registrados.' : null);
        final label = AppFonts.inter(fontSize: 13, color: AppColors.staffInk);
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Reposición de stock', onBack: () { if (!state.mutationBusy) _back(context); }),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 24, 16, 24), children: [
            if (loading && products.isEmpty)
              _muted('Cargando...')
            else ...[
              Text('Montura', style: label),
              const SizedBox(height: 10),
              StaffSelect(
                text: selected == null ? 'Elige una montura' : '${selected.name} · ${selected.sku}',
                onTap: () async {
                  final sku = await _pick(context, 'Montura', [for (final p in products) (p.sku, '${p.name} · ${p.sku}')], selected?.sku);
                  if (sku != null) setState(() => selectedSku = sku);
                },
              ),
              const SizedBox(height: 22),
              Text('Proveedor', style: label),
              const SizedBox(height: 10),
              StaffSelect(
                text: supplier?.name ?? 'Sin proveedores',
                onTap: () async {
                  if (suppliers.isEmpty) return;
                  final id = await _pick(context, 'Proveedor', [for (final s in suppliers) (s.id, s.name)], supplier?.id);
                  if (id != null) setState(() => supplierId = id);
                },
              ),
              const SizedBox(height: 22),
              Text('Unidades que ingresan', style: label),
              const SizedBox(height: 10),
              Container(
                height: 52,
                decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lavender)),
                child: Row(children: [
                  _Step('−', () => setState(() => quantity = (quantity - 1).clamp(1, maxReplenishment))),
                  Expanded(
                    child: Container(
                      color: AppColors.white.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: Text('$quantity', style: AppFonts.inter(fontSize: 16, color: AppColors.staffInk)),
                    ),
                  ),
                  _Step('+', () => setState(() => quantity = (quantity + 1).clamp(1, maxReplenishment))),
                ]),
              ),
              const SizedBox(height: 22),
              const StaffLabel('Stock mínimo', trailing: 'Opcional'),
              const SizedBox(height: 8),
              StaffInput(
                controller: minimum,
                placeholder: selected?.minimumStock == null ? '5 por defecto' : 'Actual: ${selected!.minimumStock}',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const StaffIconTile(LucideIcons.layoutGrid, size: 36, background: AppColors.lavender, color: AppColors.electric, radius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Stock resultante: ${current + quantity} unidades', style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                      Text('Stock actual: $current unidades', style: AppFonts.inter(fontSize: 9, color: _indigoText)),
                    ]),
                  ),
                ]),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
              ],
              const SizedBox(height: 32),
              StaffButton(
                label: state.mutationBusy ? 'Registrando...' : 'Registrar reposición',
                onPressed: state.mutationBusy || loading ? null : () => _submit(selected?.sku, supplier?.id),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.text, this.onTap);
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: 48, child: Center(child: Text(text, style: AppFonts.inter(fontSize: 18, color: AppColors.staffAccent)))),
      );
}

/// Alta de una montura en el catálogo (`/s/inventory/new`), igual a Kotlin.
class NewFrameScreen extends StatefulWidget {
  const NewFrameScreen({super.key});
  @override
  State<NewFrameScreen> createState() => _NewFrameScreenState();
}

class _NewFrameScreenState extends State<NewFrameScreen> {
  final _vm = getIt<NewFrameViewModel>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _material = TextEditingController();
  final _shape = TextEditingController();
  final _color = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  final _minimum = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.load();
    _vm.addListener(_onCreated);
  }

  void _onCreated() {
    final sku = _vm.state.createdSku;
    if (sku == null || !mounted) return;
    _vm.removeListener(_onCreated);
    showAppMessage(context, _vm.state.error ?? 'Montura registrada');
    context.pushReplacement('/s/product/${Uri.encodeComponent(sku)}');
  }

  @override
  void dispose() {
    _vm.removeListener(_onCreated);
    _vm.dispose();
    for (final c in [_sku, _name, _material, _shape, _color, _price, _quantity, _minimum]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() => _vm.submit(
        sku: _sku.text,
        name: _name.text,
        material: _material.text,
        shape: _shape.text,
        color: _color.text,
        price: _price.text,
        quantity: _quantity.text,
        minimum: _minimum.text,
      );

  Widget _field(String label, TextEditingController controller, String placeholder,
      {bool optional = false, TextInputType? keyboardType, List<TextInputFormatter>? formatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StaffLabel(label, trailing: optional ? 'Opcional' : null),
        const SizedBox(height: 8),
        StaffInput(controller: controller, placeholder: placeholder, keyboardType: keyboardType, inputFormatters: formatters),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)];
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        return StaffScaffold(
          tab: null,
          showBottomBar: false,
          topBar: StaffTopBar(title: 'Nueva montura', onBack: () => _back(context)),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
            _field('SKU', _sku, 'Ej. RB-2140-BLK', formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
              LengthLimitingTextInputFormatter(100),
              TextInputFormatter.withFunction((_, value) => value.copyWith(text: value.text.toUpperCase())),
            ]),
            _field('Nombre', _name, 'Ej. Ray-Ban Wayfarer', formatters: [LengthLimitingTextInputFormatter(255)]),
            _field('Material', _material, 'Ej. Acetato', optional: true, formatters: [LengthLimitingTextInputFormatter(100)]),
            _field('Forma', _shape, 'Ej. Cuadrada', optional: true, formatters: [LengthLimitingTextInputFormatter(100)]),
            _field('Color', _color, 'Ej. Negro', optional: true, formatters: [LengthLimitingTextInputFormatter(100)]),
            _field('Precio (S/)', _price, '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(11)]),
            if (state.withStock) ...[
              const SizedBox(height: 8),
              Text('Stock inicial en tu óptica', style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
              const SizedBox(height: 14),
              _field('Unidades', _quantity, '0 para ingresarlas después', optional: true, keyboardType: TextInputType.number, formatters: digits),
              _field('Stock mínimo', _minimum, '5 por defecto', optional: true, keyboardType: TextInputType.number, formatters: digits),
              Text('Proveedor', style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
              const SizedBox(height: 8),
              StaffSelect(
                text: state.supplier?.name ?? 'Sin proveedores',
                onTap: () async {
                  if (state.suppliers.isEmpty) return;
                  final id = await _pick(context, 'Proveedor', [for (final s in state.suppliers) (s.id, s.name)], state.supplierId);
                  if (id != null) _vm.selectSupplier(id);
                },
              ),
              const SizedBox(height: 16),
            ],
            if (state.createdSku == null && state.error != null) ...[
              Text(state.error!, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            StaffButton(label: state.saving ? 'Registrando...' : 'Registrar montura', onPressed: state.saving ? null : _submit),
          ]),
        );
      },
    );
  }
}
