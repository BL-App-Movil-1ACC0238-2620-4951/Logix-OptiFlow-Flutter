import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/frame_image.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final sku = TextEditingController();
  bool loading = false;
  String? error;
  @override
  void dispose() { sku.dispose(); super.dispose(); }

  Future<void> _lookup() async {
    if (loading || sku.text.trim().isEmpty) return;
    setState(() { loading = true; error = null; });
    final catalogVm = getIt<CatalogViewModel>();
    final selected = sku.text.trim();
    final frame = await catalogVm.loadFrame(selected, forInventory: true);
    if (!mounted) return;
    setState(() { loading = false; error = frame == null ? catalogVm.state.frameErrors[selected] ?? 'No se encontró la montura.' : null; });
    if (frame != null) context.push('/s/product/${Uri.encodeComponent(frame.sku)}');
  }

  @override
  Widget build(BuildContext context) => StaffScaffold(
    tab: StaffTab.inventory,
    topBar: StaffTopBar(title: 'Buscar por SKU', onBack: () => context.canPop() ? context.pop() : context.go('/s/inventory')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Ingresa el SKU que aparece en la etiqueta de la montura.'),
      const SizedBox(height: 16),
      TextField(controller: sku, enabled: !loading, onSubmitted: (_) => _lookup(), decoration: const InputDecoration(labelText: 'SKU', prefixIcon: Icon(Icons.qr_code))),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.errorRed))),
      const SizedBox(height: 20),
      SolidButton(label: 'Consultar montura', loading: loading, onPressed: _lookup),
    ]),
  );
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) getIt<CatalogViewModel>().loadFrame(widget.id, forInventory: true); });
  }

  Future<void> _editPrice(CatalogViewModel catalogVm) async {
    final value = TextEditingController(text: catalogVm.frameById(widget.id)?.price.toStringAsFixed(2) ?? '');
    String? error;
    bool saving = false;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => StatefulBuilder(builder: (context, update) => AlertDialog(
      title: const Text('Actualizar precio en soles'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: value, enabled: !saving, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio S/', helperText: 'Mayor a cero, máximo dos decimales')),
        if (error != null) Text(error!, style: const TextStyle(color: AppColors.errorRed)),
      ]),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(onPressed: saving ? null : () async {
          final price = num.tryParse(value.text.trim().replaceAll(',', '.'));
          if (price == null) { update(() => error = 'Ingresa un precio válido.'); return; }
          update(() { saving = true; error = null; });
          final saved = await catalogVm.updateFramePrice(widget.id, price);
          if (!dialogContext.mounted) return;
          if (saved) { Navigator.pop(dialogContext); } else { update(() { saving = false; error = catalogVm.state.mutationError; }); }
        }, child: Text(saving ? 'Guardando…' : 'Guardar precio')),
      ],
    )));
    value.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([catalogVm, sessionVm]),
      builder: (context, _) {
        final product = catalogVm.productById(widget.id);
        return StaffScaffold(
          tab: StaffTab.inventory,
          topBar: StaffTopBar(title: 'Montura', onBack: () => context.canPop() ? context.pop() : context.go('/s/inventory')),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            if (catalogVm.state.frameLoading.contains(widget.id)) const LinearProgressIndicator(),
            if (catalogVm.state.frameErrors[widget.id] != null) ...[
              Text(catalogVm.state.frameErrors[widget.id]!, style: const TextStyle(color: AppColors.errorRed)),
              TextButton(onPressed: () => catalogVm.loadFrame(widget.id, forInventory: true), child: const Text('Reintentar')),
            ],
            if (product != null) ...[
              FrameImage(path: product.image, height: 200),
              const SizedBox(height: 16),
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                Text('SKU: ${product.sku}'),
                Text(product.detail),
                const SizedBox(height: 12),
                Text(product.price, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(product.quantityKnown ? 'Stock de mi óptica: ${product.available} unidades' : 'Stock no disponible'),
                if (product.minimumStock != null) Text('Mínimo: ${product.minimumStock} unidades'),
              ])),
              const SizedBox(height: 16),
              SolidButton(label: 'Actualizar precio', loading: catalogVm.state.mutationBusy, onPressed: () => _editPrice(catalogVm)),
              if (sessionVm.canOpen('/s/movement')) ...[
                const SizedBox(height: 12),
                SolidButton(label: 'Stock y movimientos', onPressed: () => context.push('/s/stock/${Uri.encodeComponent(product.sku)}')),
              ],
            ],
          ]),
        );
        },
    );
  }
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _refresh(); });
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    return ListenableBuilder(
      listenable: catalogVm,
      builder: (context, _) {
        final product = catalogVm.productById(widget.id);
        final movements = catalogVm.state.movements.where((movement) => movement.sku == widget.id).toList();
        return StaffScaffold(
          tab: StaffTab.inventory,
          topBar: StaffTopBar(title: 'Stock y movimientos', onBack: () => context.canPop() ? context.pop() : context.go('/s/inventory')),
          body: RefreshIndicator(onRefresh: _refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
            if (catalogVm.state.frameErrors[widget.id] != null) Text(catalogVm.state.frameErrors[widget.id]!, style: const TextStyle(color: AppColors.errorRed)),
            if (product != null) AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: Theme.of(context).textTheme.titleLarge),
              Text(product.sku),
              Text(product.quantityKnown ? '${product.available} unidades en mi óptica' : 'Stock no disponible'),
              if (product.minimumStock != null) Text('Mínimo: ${product.minimumStock}'),
            ])),
            const SizedBox(height: 16),
            SolidButton(label: 'Registrar ingreso de proveedor', onPressed: () => context.push(Uri(path: '/s/movement', queryParameters: {'sku': widget.id}).toString())),
            const SizedBox(height: 16),
            TextButton.icon(icon: const Icon(Icons.date_range), label: Text(range == null ? 'Últimos 30 días · cambiar fechas' : '${DateFormat('dd/MM/yyyy').format(range!.start)} – ${DateFormat('dd/MM/yyyy').format(range!.end)}'), onPressed: () async {
              final selected = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now(), initialDateRange: range);
              if (selected == null || !mounted) return;
              setState(() => range = selected);
              await catalogVm.refreshStockMovements(sku: widget.id, from: selected.start, to: selected.end);
            }),
            if (catalogVm.state.movementsLoading || catalogVm.state.frameLoading.contains(widget.id)) const LinearProgressIndicator(),
            if (catalogVm.state.movementsError != null) ...[
              Text(catalogVm.state.movementsError!, style: const TextStyle(color: AppColors.errorRed)),
              TextButton(onPressed: _refresh, child: const Text('Reintentar')),
            ],
            if (!catalogVm.state.movementsLoading && catalogVm.state.movementsError == null && movements.isEmpty) const Text('No hay movimientos en este período.'),
            for (final movement in movements) ListTile(
              leading: Icon(movement.type == 'IN' ? Icons.south_west : Icons.north_east),
              title: Text('${movement.type == 'IN' ? 'Ingreso' : 'Salida'} · ${movement.quantity} unidades'),
              subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(movement.createdAt)} · ${_movementReason(movement.reason)}'),
            ),
          ])),
        );
        },
    );
  }
}

class NewMovementScreen extends StatefulWidget {
  const NewMovementScreen({super.key, this.sku});
  final String? sku;
  @override
  State<NewMovementScreen> createState() => _NewMovementScreenState();
}

String _movementReason(String value) => switch (value) {
  'REPLENISHMENT' => 'Reposición de proveedor',
  'SALE' => 'Venta',
  'ADJUSTMENT' => 'Ajuste',
  _ => 'Movimiento de stock',
};

class _NewMovementScreenState extends State<NewMovementScreen> {
  String? selectedSku;
  String? supplierId;
  final quantity = TextEditingController(text: '1');
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
  void dispose() { quantity.dispose(); minimum.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final catalogVm = getIt<CatalogViewModel>();
    if (catalogVm.state.mutationBusy) return;
    final units = int.tryParse(quantity.text.trim());
    final threshold = minimum.text.trim().isEmpty ? null : int.tryParse(minimum.text.trim());
    if (selectedSku == null || supplierId == null || !catalogVm.state.products.any((item) => item.sku == selectedSku) || !catalogVm.state.suppliers.any((item) => item.id == supplierId) || units == null || (minimum.text.trim().isNotEmpty && threshold == null)) {
      showAppMessage(context, 'Selecciona montura y proveedor e ingresa cantidades enteras.');
      return;
    }
    final saved = await catalogVm.replenishStock(sku: selectedSku!, supplierId: supplierId!, quantity: units, minimumStock: threshold);
    if (!mounted || !saved) return;
    await catalogVm.refreshStockMovements(sku: selectedSku);
    if (!mounted) return;
    showAppMessage(context, catalogVm.state.inventoryError == null ? 'Ingreso registrado' : 'Ingreso registrado. Reintenta actualizar el stock desde inventario.');
    if (context.canPop()) { context.pop(); } else { context.go('/s/inventory'); }
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    return ListenableBuilder(
      listenable: catalogVm,
      builder: (context, _) {
        final loading = catalogVm.state.inventoryLoading || catalogVm.state.suppliersLoading;
        final busy = catalogVm.state.mutationBusy;
        return StaffScaffold(
          tab: StaffTab.inventory,
          topBar: StaffTopBar(title: 'Ingreso de proveedor', onBack: () { if (!busy) { context.canPop() ? context.pop() : context.go('/s/inventory'); } }),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Registra las unidades que entregó un proveedor a tu óptica. Las salidas se registran mediante las ventas.'),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (catalogVm.state.inventoryError != null) Text(catalogVm.state.inventoryError!, style: const TextStyle(color: AppColors.errorRed)),
            if (catalogVm.state.suppliersError != null) Text(catalogVm.state.suppliersError!, style: const TextStyle(color: AppColors.errorRed)),
            if (catalogVm.state.inventoryError != null || catalogVm.state.suppliersError != null)
              TextButton(onPressed: loading || busy ? null : () { catalogVm.refreshInventory(); catalogVm.refreshSuppliers(); }, child: const Text('Volver a cargar opciones')),
            DropdownButtonFormField<String>(
              key: ValueKey('sku-${catalogVm.state.products.length}-$selectedSku'),
              initialValue: catalogVm.state.products.any((item) => item.sku == selectedSku) ? selectedSku : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Montura'),
              items: [for (final item in catalogVm.state.products) DropdownMenuItem(value: item.sku, child: Text('${item.sku} · ${item.name}', overflow: TextOverflow.ellipsis))],
              onChanged: busy || loading ? null : (value) => setState(() => selectedSku = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('supplier-${catalogVm.state.suppliers.length}-$supplierId'),
              initialValue: catalogVm.state.suppliers.any((item) => item.id == supplierId) ? supplierId : null, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Proveedor'),
              items: [for (final supplier in catalogVm.state.suppliers) DropdownMenuItem(value: supplier.id, child: Text(supplier.name, overflow: TextOverflow.ellipsis))],
              onChanged: busy || loading ? null : (value) => setState(() => supplierId = value),
            ),
            if (!loading && catalogVm.state.suppliersError == null && catalogVm.state.suppliers.isEmpty) const Text('No hay proveedores registrados. Registra uno desde las herramientas de administración.'),
            const SizedBox(height: 16),
            TextField(controller: quantity, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad recibida', helperText: 'De 1 a 1000 unidades')),
            const SizedBox(height: 16),
            TextField(controller: minimum, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nuevo stock mínimo (opcional)', helperText: 'Vacío conserva el mínimo actual; para un stock nuevo se aplica 5.')),
            if (catalogVm.state.mutationError != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(catalogVm.state.mutationError!, style: const TextStyle(color: AppColors.errorRed))),
            const SizedBox(height: 24),
            SolidButton(label: 'Registrar ingreso', loading: busy, onPressed: loading || catalogVm.state.inventoryError != null || catalogVm.state.suppliersError != null || catalogVm.state.products.isEmpty || catalogVm.state.suppliers.isEmpty ? null : _submit),
          ]),
        );
        },
    );
  }
}
