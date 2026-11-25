import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    return ListenableBuilder(
      listenable: patientVm,
      builder: (context, _) {
        final orders = patientVm.state.orders.where((order) => tab == 0 ? !order.delivered : order.delivered).toList();
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
                Text(tab == 0 ? 'Pedido activo' : 'Pedidos entregados', style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 12),
                for (final order in orders) ...[
                  _OrderCard(order),
                  const SizedBox(height: 14),
                ],
              ],
              const SizedBox(height: 48),
              Column(
                children: [
                  const IconTile(icon: LucideIcons.box, background: AppColors.white, color: AppColors.navyBlue, size: 56, iconSize: 22),
                  const SizedBox(height: 14),
                  Text(
                    tab == 0 ? 'No tienes más pedidos activos' : 'No tienes más pedidos entregados',
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Text('Aquí verás el avance de tus próximos lentes.', style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                ],
              ),
            ],
          ),
        );
        },
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
            child: Center(child: Text(label, style: AppFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.deepNavy))),
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
              const IconTile(icon: LucideIcons.eye, background: AppColors.periwinkle, color: AppColors.deepNavy, size: 50, iconSize: 22),
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
                          const Icon(LucideIcons.package, size: 12, color: AppColors.electric),
                          const SizedBox(width: 4),
                          Text(order.delivered ? 'Entregado' : order.statusLabel, style: AppFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.electric)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(order.title, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    Text('Pedido #${order.code} · ${order.dateLabel}', style: AppFonts.inter(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.slate500, size: 20),
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
              Expanded(child: Text('Pedido recibido', style: AppFonts.inter(fontSize: 11, color: AppColors.deepNavy))),
              Text(order.statusLabel, style: AppFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lavender),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AppFonts.inter(fontSize: 12, color: AppColors.slate500),
              children: [
                const TextSpan(text: 'Entrega estimada:  '),
                TextSpan(text: order.estimate.replaceAll(' y ', '–'), style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
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
    final patientVm = getIt<PatientViewModel>();
    return ListenableBuilder(
      listenable: patientVm,
      builder: (context, _) {
        final order = patientVm.orderById(id);
        if (order == null) {
          return const PatientScaffold(tab: PatientTab.orders, topBar: DarkTopBar(title: 'Pedido'), body: Center(child: Text('Pedido no encontrado.')));
        }
        final steps = [
          ('Pedido recibido', order.history.firstOrNull ?? '—', LucideIcons.check),
          // La orden nace al cerrar la venta, ya pagada.
          ('Pago confirmado', order.statusDates['PENDING'] ?? order.history.firstOrNull ?? '—', LucideIcons.check),
          ('En producción', order.statusDates['IN_WORKSHOP'] ?? (order.step >= 2 ? 'Trabajando en tus lentes' : 'Pendiente'), LucideIcons.eye),
          (
            order.delivered ? 'Entregado' : 'Listo para retirar',
            order.statusDates[order.delivered ? 'DELIVERED' : 'READY_FOR_DELIVERY'] ?? 'Pendiente',
            LucideIcons.package,
          ),
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
                      child: const Icon(LucideIcons.eye, color: AppColors.navyBlue, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.skyTint)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, size: 14, color: AppColors.navyBlue),
                          const SizedBox(width: 6),
                          Text(order.delivered ? 'Entregado' : order.statusLabel, style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      order.delivered
                          ? 'Tus lentes fueron entregados'
                          : order.step >= 3
                              ? 'Tus lentes están listos para retirar'
                              : 'Tus lentes están en proceso', textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    const SizedBox(height: 6),
                    Text(order.delivered ? 'Gracias por confiar en nosotros.' : 'Entrega estimada: ${order.estimate}.', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 13, color: AppColors.slate500)),
                    if (order.delayReason != null) ...[
                      const SizedBox(height: 6),
                      Text('Tu pedido tiene un retraso: ${order.delayReason}', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 13, color: AppColors.errorRed)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Seguimiento', style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
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
                    _InfoLine(LucideIcons.eye, 'PRODUCTO', order.product, order.productDetail),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.lavender),
                    const SizedBox(height: 12),
                    _InfoLine(LucideIcons.mapPin, 'RETIRO EN', order.pickup, null),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SolidButton(
                label: '¿Necesitas ayuda?',
                icon: LucideIcons.circleQuestionMark,
                background: AppColors.white,
                foreground: AppColors.navyBlue,
                border: AppColors.skyTint,
                onPressed: () => context.push('/p/settings'),
              ),
            ],
          ),
        );
        },
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
              child: Icon(reached ? LucideIcons.check : icon, size: 14, color: active ? AppColors.white : AppColors.slate400),
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
                Text(title, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text(subtitle, style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
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
              Text(label, style: AppFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate400, letterSpacing: 0.5)),
              Text(value, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(detail!, style: AppFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
