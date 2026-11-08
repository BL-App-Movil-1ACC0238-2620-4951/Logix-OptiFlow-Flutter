import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../models/ui_models.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OptiFlowController>().orders.where((order) => tab == 0 ? !order.delivered : order.delivered).toList();
    return PatientScaffold(
      tab: PatientTab.orders,
      topBar: DarkTopBar(
        title: 'Mis Pedidos',
        onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
        below: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 22),
                _Segment(['En curso', 'Entregados'][i], tab == i, () => setState(() => tab = i)),
              ],
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        children: [
          if (orders.isNotEmpty) ...[
            Text(tab == 0 ? 'Pedido activo' : 'Pedidos entregados', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 12),
            for (final order in orders) ...[
              _OrderCard(order),
              const SizedBox(height: 14),
            ],
          ],
          const SizedBox(height: 48),
          Column(
            children: [
              const IconTile(icon: Icons.inventory_2_outlined, background: AppColors.white, color: AppColors.navyBlue, size: 56, iconSize: 22),
              const SizedBox(height: 14),
              Text(
                tab == 0 ? 'No tienes más pedidos activos' : 'No tienes más pedidos entregados',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              Text('Aquí verás el avance de tus próximos lentes.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.skyTint : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.deepNavy))),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);
  final OrderUi order;

  @override
  Widget build(BuildContext context) {
    final filled = order.step.clamp(0, 4);
    return AppCard(
      onTap: () => context.push('/p/order/${order.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: Icons.remove_red_eye_outlined, background: AppColors.periwinkle, color: AppColors.deepNavy, size: 50, iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.skyTint.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.electric),
                          const SizedBox(width: 4),
                          Text(order.delivered ? 'Entregado' : order.statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.electric)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(order.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    Text('Pedido #${order.code} · ${order.dateLabel}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate500, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i < filled ? AppColors.electric : const Color(0xFFE6EBFD), borderRadius: BorderRadius.circular(99)))),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Pedido recibido', style: GoogleFonts.inter(fontSize: 11, color: AppColors.deepNavy))),
              Text(order.statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lavender),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500),
              children: [
                const TextSpan(text: 'Entrega estimada:  '),
                TextSpan(text: order.estimate.replaceAll(' y ', '–'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OptiFlowController>().orderById(id);
    if (order == null) {
      return const PatientScaffold(tab: PatientTab.orders, topBar: DarkTopBar(title: 'Pedido'), body: Center(child: Text('Pedido no encontrado.')));
    }
    final steps = [
      ('Pedido recibido', order.history.isNotEmpty ? order.history[0] : '—', Icons.check),
      ('Pago confirmado', order.history.length > 1 ? order.history[1] : (order.history.isNotEmpty ? order.history[0] : '—'), Icons.check),
      ('En producción', 'Trabajando en tus lentes', Icons.remove_red_eye_outlined),
      ('Listo para retirar', 'Próximamente', Icons.inventory_2_outlined),
    ];
    return PatientScaffold(
      tab: PatientTab.orders,
      topBar: DarkTopBar(title: 'Pedido #${order.code}', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          AppCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x1400135B), blurRadius: 6, offset: Offset(0, 2))]),
                  child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.navyBlue, size: 24),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.skyTint)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: AppColors.navyBlue),
                      const SizedBox(width: 6),
                      Text(order.delivered ? 'Entregado' : order.statusLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(order.delivered ? 'Tus lentes fueron entregados' : 'Tus lentes están en proceso', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 6),
                Text('Entrega estimada entre el ${order.estimate}.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Seguimiento', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 14),
          for (var index = 0; index < steps.length; index++)
            _TrackStep(
              title: steps[index].$1,
              subtitle: steps[index].$2,
              icon: steps[index].$3,
              reached: index < order.step || order.delivered,
              current: index == order.step && !order.delivered,
              last: index == steps.length - 1,
              lineOn: index < order.step,
            ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _InfoLine(Icons.remove_red_eye_outlined, 'PRODUCTO', order.product, order.productDetail),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.lavender),
                const SizedBox(height: 12),
                _InfoLine(Icons.place_outlined, 'RETIRO EN', order.pickup, null),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SolidButton(
            label: '¿Necesitas ayuda?',
            icon: Icons.help_outline,
            background: AppColors.white,
            foreground: AppColors.navyBlue,
            border: AppColors.skyTint,
            onPressed: () => context.push('/p/settings'),
          ),
        ],
      ),
    );
  }
}

class _TrackStep extends StatelessWidget {
  const _TrackStep({required this.title, required this.subtitle, required this.icon, required this.reached, required this.current, required this.last, required this.lineOn});
  final String title;
  final String subtitle;
  final IconData icon;
  final bool reached;
  final bool current;
  final bool last;
  final bool lineOn;

  @override
  Widget build(BuildContext context) {
    final active = reached || current;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active ? AppColors.navyBlue : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: active ? AppColors.navyBlue : const Color(0xFFE2E8F0)),
              ),
              child: Icon(reached ? Icons.check : icon, size: 14, color: active ? AppColors.white : AppColors.slate400),
            ),
            if (!last) Container(width: 2, height: 27, color: lineOn ? AppColors.navyBlue : const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.label, this.value, this.detail);
  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon, size: 20, color: AppColors.navyBlue)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate400, letterSpacing: 0.5)),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(detail!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
