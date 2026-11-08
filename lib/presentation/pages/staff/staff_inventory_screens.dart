import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F3A6D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 28)),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Escanear producto', style: GoogleFonts.inter(fontSize: 14, color: AppColors.white)),
                        Text('Alinea el código dentro del marco', style: GoogleFonts.inter(fontSize: 11, color: AppColors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  const Icon(Icons.help_outline, color: AppColors.white, size: 22),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: const Color(0xFF1E4383), borderRadius: BorderRadius.circular(24)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(width: 250, height: 180, child: CustomPaint(painter: _ScanCornersPainter())),
                      Positioned(
                        bottom: 48,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x3300135B), blurRadius: 8, offset: Offset(0, 3))]),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: AppColors.white, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Código detectado', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                                  Text('NV-N24-AZ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  _ScanAction(Icons.flashlight_on_outlined, 'Linterna', () => showAppMessage(context, 'Linterna activada')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SolidButton(label: 'Ver producto', background: AppColors.staffAccent, onPressed: () => context.push('/s/product/rb5154')),
                  ),
                  const SizedBox(width: 16),
                  const _ScanAction(Icons.edit_outlined, 'Ingresar código', null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanAction extends StatelessWidget {
  const _ScanAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

class _ScanCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin + Offset(len * dx, 0), paint);
      canvas.drawLine(origin, origin + const Offset(0, 0) + Offset(0, len * dy), paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
    final scan = Paint()
      ..shader = const LinearGradient(colors: [Color(0x66FFFFFF), AppColors.white, Color(0x66FFFFFF)]).createShader(Rect.fromLTWH(0, size.height / 2, size.width, 4))
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), scan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int thumb = 0;

  @override
  Widget build(BuildContext context) {
    final product = context.read<OptiFlowController>().productById(widget.id);
    final stock = context.watch<OptiFlowController>().stockOf(product);
    final gallery = [product.image, 'assets/images/img_prod_thumb2.png', 'assets/images/img_eval_frame.png'];
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Detalle del producto', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AppCard(
            radius: 20,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(gallery[thumb], height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < gallery.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => thumb = i),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: thumb == i ? AppColors.staffAccent : Colors.transparent, width: 1.5),
                            ),
                            child: ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset(gallery[i], fit: BoxFit.cover)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(20)),
              child: Text('$stock unidades disponibles', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
            ),
          ),
          const SizedBox(height: 12),
          Text(product.name, style: GoogleFonts.inter(fontSize: 22, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text('${product.sku} · Carey y dorado · Acetato con metal', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
          const SizedBox(height: 14),
          Text(product.price, style: GoogleFonts.inter(fontSize: 20, color: AppColors.staffInk)),
          const SizedBox(height: 18),
          AppCard(
            color: const Color(0xFFF7F9FF),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _InfoCell('Código', product.code)),
                    Expanded(child: _InfoCell('Talla', product.size.replaceAll('-', '–'))),
                  ],
                ),
                const Divider(height: 1, color: AppColors.lavender),
                Row(
                  children: [
                    Expanded(child: _InfoCell('Ubicación', product.location)),
                    Expanded(child: _InfoCell('Proveedor', product.supplier)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: SolidButton(label: 'Ver stock', background: AppColors.white, foreground: AppColors.staffInk, border: AppColors.staffBorder, onPressed: () => context.push('/s/stock/${product.id}'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: SolidButton(label: 'Agregar', onPressed: () => context.push('/s/sale'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
        ],
      ),
    );
  }
}

class StockManagementScreen extends StatelessWidget {
  const StockManagementScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final product = app.productById(id);
    final stock = app.stockOf(product);
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Detalle y gestión de stock', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(color: AppColors.staffHeader, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('CONTROL DE LOTE · REF #${product.sku}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate300, letterSpacing: 0.4))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text(product.supplier, style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffInk)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(product.name, style: GoogleFonts.inter(fontSize: 20, color: AppColors.white)),
                Text('${product.sku} 2000 · Carey & Dorado Vintage (Acetato + Metal)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(product.image, width: 68, height: 44, fit: BoxFit.cover)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SKU PRIMARIO', style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate300)),
                          Text(product.code, style: GoogleFonts.inter(fontSize: 16, color: AppColors.white)),
                          Text('Calibre 51 · Puente 21 · Varilla 145', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => context.push('/s/scanner'), icon: const Icon(Icons.qr_code_scanner, color: AppColors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PriceBit('PVP SUGERIDO', product.price),
                    _PriceBit('COSTO UNIT.', '\$98.500'),
                    _PriceBit('MARGEN', '48% Bruto', alignEnd: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StockStat(icon: Icons.inventory_2_outlined, tileBg: AppColors.errorBg, tint: AppColors.errorRed, pill: 'Bajo', value: '$stock', valueColor: AppColors.errorRed, title: 'Stock actual', subtitle: 'Total físico red')),
              const SizedBox(width: 10),
              Expanded(child: _StockStat(icon: Icons.description_outlined, tileBg: const Color(0xFFEEF2FF), tint: AppColors.staffAccent, pill: 'Objetivo', value: '6', valueColor: AppColors.staffInk, title: 'Mínimo umbral', subtitle: 'Déficit: ${stock - 6} uds')),
            ],
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const IconTile(icon: Icons.inventory_2_outlined, background: Color(0xFFEEF2FF), color: AppColors.staffAccent, size: 34, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('12 en tránsito', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                          const SizedBox(width: 8),
                          Text('Hoy 16:30', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
                        ],
                      ),
                      Text('Despacho Guía #EX-90412 · Essilor Central', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.staffInk),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ajuste manual rápido', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                      Text('Registrar merma, rotura o conteo', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                    ],
                  ),
                ),
                _Step('-', stock > 0 ? () => app.adjustStock(product.id, -1) : null),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$stock', style: GoogleFonts.inter(fontSize: 18, color: AppColors.staffInk))),
                _Step('+', () => app.adjustStock(product.id, 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section('Disponibilidad en red', trailing: '3 puntos'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: const [
                _NetworkRow(Icons.grid_view, 'Vitrina Sucursal Centro', '2 unidades (Bajo mínimo)', 'Auditar'),
                Divider(height: 1, color: AppColors.staffBorder),
                _NetworkRow(Icons.home_outlined, 'Cajón Taller / Bodega', '2 unidades operativas', 'Mover'),
                Divider(height: 1, color: AppColors.staffBorder),
                _NetworkRow(Icons.inventory_2_outlined, 'Sucursal Norte', '0 unidades (Agotado)', 'Sin stock', danger: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Section('Acciones directas'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _DirectAction(Icons.chevron_right, 'Trasladar', 'Enviar a otra sucursal', () => context.push('/s/movement'))),
              const SizedBox(width: 10),
              Expanded(child: _DirectAction(Icons.description_outlined, 'Etiqueta', 'Imprimir código barras', () => showAppMessage(context, 'Etiqueta enviada a la impresora'))),
            ],
          ),
          const SizedBox(height: 24),
          const _Section('Últimos movimientos', trailing: 'Ver kardex'),
          const SizedBox(height: 12),
          const _MovementRow(Icons.credit_card, 'Venta en tienda #8839', 'Boleta B-1092 · Hoy, 11:20 · Vendedora: Camila R.', '-1 ud', AppColors.errorRed),
          const SizedBox(height: 10),
          const _MovementRow(Icons.inventory_2_outlined, 'Recepción lote Essilor', 'Factura Prov #77102 · 18 jun, 09:45', '+5 uds', AppColors.staffGreen),
          const SizedBox(height: 16),
          SolidButton(label: 'Solicitar pedido de reposición', icon: Icons.add, onPressed: () => showAppMessage(context, 'Pedido de reposición solicitado')),
        ],
      ),
    );
  }
}

class _PriceBit extends StatelessWidget {
  const _PriceBit(this.label, this.value, {this.alignEnd = false});
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.slate300)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.white)),
        ],
      ),
    );
  }
}

class _StockStat extends StatelessWidget {
  const _StockStat({required this.icon, required this.tileBg, required this.tint, required this.pill, required this.value, required this.valueColor, required this.title, required this.subtitle});
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, background: tileBg, color: tint, size: 32, iconSize: 16),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.staffChip, borderRadius: BorderRadius.circular(20)),
                child: Text(pill, style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.inter(fontSize: 24, color: valueColor)),
          Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 30, height: 30, child: Center(child: Text(label, style: GoogleFonts.inter(fontSize: 16, color: AppColors.staffAccent)))),
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow(this.icon, this.title, this.subtitle, this.action, {this.danger = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconTile(icon: icon, background: const Color(0xFFEEF2FF), color: AppColors.staffAccent, size: 34, iconSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: danger ? AppColors.errorRed : AppColors.staffAccent)),
              ],
            ),
          ),
          Text(action, style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
        ],
      ),
    );
  }
}

class _DirectAction extends StatelessWidget {
  const _DirectAction(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, background: const Color(0xFFEEF2FF), color: AppColors.staffAccent, size: 30, iconSize: 16),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow(this.icon, this.title, this.subtitle, this.delta, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final String delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(icon: icon, background: const Color(0xFFEEF2FF), color: AppColors.staffAccent, size: 32, iconSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffInk)),
              ],
            ),
          ),
          Text(delta, style: GoogleFonts.inter(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk))),
        if (trailing != null) Text(trailing!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffAccent)),
      ],
    );
  }
}

class NewMovementScreen extends StatefulWidget {
  const NewMovementScreen({super.key});

  @override
  State<NewMovementScreen> createState() => _NewMovementScreenState();
}

class _NewMovementScreenState extends State<NewMovementScreen> {
  static const reasons = ['Reposición de proveedor', 'Devolución de cliente', 'Traslado entre sucursales', 'Merma o rotura'];
  int type = 0;
  int qty = 1;
  int reason = 0;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<OptiFlowController>().stockOf(context.read<OptiFlowController>().productById('rb5154'));
    final result = switch (type) {
      0 => current + qty,
      1 => current - qty,
      _ => qty,
    };
    return StaffScaffold(
      tab: StaffTab.inventory,
      topBar: StaffTopBar(title: 'Nuevo movimiento', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Tipo de movimiento', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 14),
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => type = i),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: type == i ? AppColors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                        child: Text(['Ingreso', 'Salida', 'Ajuste'][i], style: GoogleFonts.inter(fontSize: 12, color: type == i ? AppColors.staffAccent : AppColors.staffInk)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Cantidad', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          const SizedBox(height: 10),
          Container(
            height: 52,
            decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lavender)),
            child: Row(
              children: [
                _QtyButton('−', () => setState(() => qty = qty > 1 ? qty - 1 : 1)),
                Expanded(child: Center(child: Text('$qty', style: GoogleFonts.inter(fontSize: 16, color: AppColors.staffInk)))),
                _QtyButton('+', () => setState(() => qty++)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Motivo', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          const SizedBox(height: 10),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => setState(() => reason = (reason + 1) % reasons.length),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lavender)),
                child: Row(
                  children: [
                    Expanded(child: Text(reasons[reason], style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk))),
                    const Icon(Icons.expand_more, color: AppColors.staffInk),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('Nota', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
              const Spacer(),
              Text('Opcional', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Agrega un detalle del movimiento...',
              filled: true,
              fillColor: AppColors.staffField,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lavender)),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const IconTile(icon: Icons.grid_view, background: AppColors.lavender, color: AppColors.electric, size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock resultante: $result unidades', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                    Text('Stock actual: $current unidades', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SolidButton(
            label: 'Confirmar movimiento',
            onPressed: () {
              final delta = switch (type) {
                0 => qty,
                1 => -qty,
                _ => 0,
              };
              context.read<OptiFlowController>().adjustStock('rb5154', delta);
              showAppMessage(context, 'Movimiento registrado');
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(width: 48, height: 52, child: Center(child: Text(label, style: GoogleFonts.inter(fontSize: 18, color: AppColors.staffAccent)))),
    );
  }
}
