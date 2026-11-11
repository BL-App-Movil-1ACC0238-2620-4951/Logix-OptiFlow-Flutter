import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

class NewFrameScreen extends StatefulWidget {
  const NewFrameScreen({super.key});

  @override
  State<NewFrameScreen> createState() => _NewFrameScreenState();
}

class _NewFrameScreenState extends State<NewFrameScreen> {
  final skuCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final materialCtrl = TextEditingController();
  final shapeCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '5');
  final minCtrl = TextEditingController(text: '3');
  String selectedSupplier = 'EssilorLuxottica';

  @override
  void dispose() {
    skuCtrl.dispose();
    nameCtrl.dispose();
    materialCtrl.dispose();
    shapeCtrl.dispose();
    colorCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    minCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final sku = skuCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final price = priceCtrl.text.trim();

    if (sku.isEmpty || name.isEmpty || price.isEmpty) {
      showAppMessage(context, 'Completa SKU, nombre y precio para continuar.');
      return;
    }

    final stock = int.tryParse(qtyCtrl.text.trim()) ?? 5;
    context.read<OptiFlowController>().addNewFrame(
          sku: sku,
          name: name,
          price: price,
          material: materialCtrl.text.trim(),
          shape: shapeCtrl.text.trim(),
          color: colorCtrl.text.trim(),
          initialStock: stock,
          supplier: selectedSupplier,
        );

    showAppMessage(context, 'Montura $name registrada en catálogo.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<OptiFlowController>().suppliers;
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Nueva montura', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU *', hintText: 'Ej. RB-2140-BLK')),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre *', hintText: 'Ej. Ray-Ban Wayfarer')),
          const SizedBox(height: 12),
          TextField(controller: materialCtrl, decoration: const InputDecoration(labelText: 'Material (opcional)', hintText: 'Ej. Acetato premium')),
          const SizedBox(height: 12),
          TextField(controller: shapeCtrl, decoration: const InputDecoration(labelText: 'Forma (opcional)', hintText: 'Ej. Cuadrada, Redonda, Aviador')),
          const SizedBox(height: 12),
          TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Color (opcional)', hintText: 'Ej. Negro brillante, Carey')),
          const SizedBox(height: 12),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (CLP / \$) *', hintText: '145.000')),
          const SizedBox(height: 20),
          Text('Stock inicial en tu óptica', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unidades', hintText: '5'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock mínimo', hintText: '3'))),
            ],
          ),
          const SizedBox(height: 12),
          Text('Proveedor', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: suppliers.any((s) => s.name == selectedSupplier) ? selectedSupplier : suppliers.firstOrNull?.name,
                isExpanded: true,
                items: suppliers.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedSupplier = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SolidButton(label: 'Registrar montura', icon: Icons.check, onPressed: _submit),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
