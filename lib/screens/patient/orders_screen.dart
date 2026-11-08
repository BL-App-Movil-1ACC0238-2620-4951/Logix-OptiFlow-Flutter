import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OptiFlowController>().orders;
    return PatientScaffold(
      tab: PatientTab.orders,
      topBar: const DarkTopBar(title: 'Mis pedidos'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final order in orders) ...[
            AppCard(
              onTap: () => context.push('/p/order/${order.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(order.code, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric))),
                      StatusCapsule(order.statusLabel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(order.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text(order.product, style: GoogleFonts.inter(color: AppColors.slate500)),
                  const SizedBox(height: 10),
                  _Stepper(step: order.step),
                  const SizedBox(height: 8),
                  Text('Entrega estimada: ${order.estimate}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
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
    const labels = ['Recibido', 'Pago', 'Producción', 'Listo', 'Entregado'];
    return PatientScaffold(
      tab: PatientTab.orders,
      topBar: DarkTopBar(title: order.code, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(order.title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 6),
          Text(order.statusLabel, style: GoogleFonts.inter(color: AppColors.electric, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.product, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text(order.productDetail, style: GoogleFonts.inter(color: AppColors.slate500)),
                const SizedBox(height: 8),
                Text('Retiro: ${order.pickup}', style: GoogleFonts.inter(color: AppColors.slate600)),
                Text('Estimado: ${order.estimate}', style: GoogleFonts.inter(color: AppColors.slate600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < labels.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(i <= order.step ? Icons.check_circle : Icons.radio_button_off, color: i <= order.step ? AppColors.emerald600 : AppColors.slate300),
              title: Text(labels[i], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
              subtitle: i < order.history.length ? Text(order.history[i]) : null,
            ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          Container(width: 10, height: 10, decoration: BoxDecoration(color: i <= step ? AppColors.electric : AppColors.slate300, shape: BoxShape.circle)),
          if (i < 4) Expanded(child: Container(height: 2, color: i < step ? AppColors.electric : AppColors.slate300)),
        ],
      ],
    );
  }
}
