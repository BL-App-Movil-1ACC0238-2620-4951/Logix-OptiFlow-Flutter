import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

/// Historial de compras del paciente — equivalente a PurchaseScreens.kt en Android.
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final purchases = app.orders;
    return PatientScaffold(
      tab: PatientTab.orders,
      topBar: DarkTopBar(title: 'Mis compras', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.staffHeader,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumen de compras', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                Text('${purchases.length} compras', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white)),
                Text('Historial completo de tus lentes y monturas.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (purchases.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.slate300),
                    const SizedBox(height: 12),
                    Text('Sin compras registradas', style: GoogleFonts.inter(color: AppColors.slate500)),
                    Text('Cuando realices una compra, aparecerá aquí.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                  ],
                ),
              ),
            ),
          for (final order in purchases) ...[
            AppCard(
              onTap: () => context.push('/p/order/${order.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: order.delivered ? AppColors.emerald50 : AppColors.periwinkle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.delivered ? 'Entregado' : 'En proceso',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: order.delivered ? AppColors.emerald600 : AppColors.electric),
                        ),
                      ),
                      const Spacer(),
                      Text(order.dateLabel, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(order.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text(order.product, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600)),
                  Text(order.productDetail, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                  const SizedBox(height: 6),
                  Text('Retiro: ${order.pickup}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                  if (order.estimate.isNotEmpty)
                    Text('Entrega: ${order.estimate}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.electric)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
