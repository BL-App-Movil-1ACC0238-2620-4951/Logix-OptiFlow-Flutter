import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Nueva cotización', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _PatientStrip('Receta del 12 mar 2025', badge: true),
          const SizedBox(height: 24),
          Text('Productos', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFF7F9FF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => context.push('/s/inventory'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.electric, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.electric, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add, color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agregar montura o lente', style: GoogleFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                          Text('Busca en el catálogo o escanea', style: GoogleFonts.inter(fontSize: 9, color: AppColors.staffInk)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.staffInk),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const _Line(title: 'Lentes monofocales', subtitle: 'Índice 1.60 · Antirreflejo', price: '\$89.900', priceColor: AppColors.staffAccent, editable: true),
          const Divider(color: AppColors.lavender),
          const SizedBox(height: 16),
          const _Totals(subtotal: '\$89.900', discount: '—', total: '\$89.900'),
          const SizedBox(height: 40),
          SolidButton(label: 'Agregar montura', onPressed: () => context.push('/s/scanner')),
        ],
      ),
    );
  }
}

class ConfirmSaleScreen extends StatelessWidget {
  const ConfirmSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Confirmar venta', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _PatientStrip('Venta asociada a receta', badge: false),
          const SizedBox(height: 24),
          Text('Resumen', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          const AppCard(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                _Line(title: 'Nova N-24', subtitle: 'Montura · Azul marino', price: '\$72.900'),
                Divider(color: AppColors.lavender),
                _Line(title: 'Lentes monofocales', subtitle: '1.60 · Antirreflejo', price: '\$89.900'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Totals(subtotal: '\$162.800', discount: '-\$10.000', total: '\$152.800'),
          const SizedBox(height: 22),
          Text('Entrega estimada', style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.staffAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text('28 de junio de 2025', style: GoogleFonts.inter(color: AppColors.staffInk))),
                const Icon(Icons.expand_more, color: AppColors.staffInk),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SolidButton(label: 'Continuar al pago', onPressed: () => context.push('/s/sale/done')),
        ],
      ),
    );
  }
}

class SaleDoneScreen extends StatelessWidget {
  const SaleDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 70),
              Container(
                width: 104,
                height: 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electric,
                  border: Border.all(color: const Color(0xFFDDE5FB), width: 12),
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text('VENTA #V-1038', style: GoogleFonts.inter(fontSize: 10, color: AppColors.staffAccent, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text('Venta confirmada', style: GoogleFonts.inter(fontSize: 26, color: AppColors.staffInk)),
              const SizedBox(height: 12),
              Text('El pago fue registrado correctamente.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.staffInk)),
              const SizedBox(height: 26),
              const AppCard(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    _Pair('Paciente', 'Valentina Silva'),
                    Divider(color: AppColors.lavender),
                    _Pair('Total', '\$152.800'),
                    Divider(color: AppColors.lavender),
                    _Pair('Pago', 'Tarjeta'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SolidButton(label: 'Volver al inicio', onPressed: () => context.go('/s/home')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientStrip extends StatelessWidget {
  const _PatientStrip(this.caption, {required this.badge});
  final String caption;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
            child: Text('VS', style: GoogleFonts.inter(fontSize: 11, color: AppColors.electric)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valentina Silva', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                Text(caption, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
              ],
            ),
          ),
          if (badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.staffBlue50, borderRadius: BorderRadius.circular(20)),
              child: Text('Receta', style: GoogleFonts.inter(fontSize: 11, color: AppColors.staffInk)),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.subtitle, required this.price, this.priceColor = AppColors.staffInk, this.editable = false});
  final String title;
  final String subtitle;
  final String price;
  final Color priceColor;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.staffInk)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 8, color: AppColors.staffInk)),
              ],
            ),
          ),
          Text(price, style: GoogleFonts.inter(fontSize: 12, color: priceColor)),
          if (editable) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.staffInk),
          ],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.subtotal, required this.discount, required this.total});
  final String subtotal;
  final String discount;
  final String total;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFF7F9FF),
      child: Column(
        children: [
          _Pair('Subtotal', subtotal),
          const SizedBox(height: 8),
          _Pair('Descuento', discount),
          const Divider(height: 20, color: AppColors.lavender),
          _Pair('Total', total, strong: true),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(fontSize: strong ? 14 : 12, fontWeight: strong ? FontWeight.w700 : FontWeight.w500, color: AppColors.staffInk);
    return Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]);
  }
}
