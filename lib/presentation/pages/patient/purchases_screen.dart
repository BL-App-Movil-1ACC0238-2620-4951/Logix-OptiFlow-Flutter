import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/purchases_view_model.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _vm = getIt<PurchasesViewModel>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _vm.load();
    // Al volver de Mercado Pago (optiflow://payment-result) se recargan las compras.
    _lifecycle = AppLifecycleListener(onResume: _vm.load);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _pay(String saleId) async {
    final url = await _vm.paymentLink(saleId);
    if (url == null) return;
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    if (!opened) _vm.showPaymentError('No se pudo abrir Mercado Pago.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        return PatientScaffold(
          tab: null,
          topBar: DarkTopBar(title: 'Mis compras', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            children: [
              if (state.loading && state.purchases.isEmpty)
                Text('Cargando tus compras...', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500))
              else if (state.error != null) ...[
                Text(state.error!, style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _vm.load,
                  child: Text('Reintentar', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.electric)),
                ),
              ] else if (state.purchases.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      const IconTile(icon: LucideIcons.receipt, background: AppColors.white, color: AppColors.navyBlue, size: 56, iconSize: 22, radius: 16),
                      const SizedBox(height: 14),
                      Text('Aún no tienes compras', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Text(
                        'Cuando compres tus lentes en una óptica, aquí verás tu boleta.',
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400),
                      ),
                    ],
                  ),
                )
              else ...[
                if (state.paymentError != null) ...[
                  Text(state.paymentError!, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.errorRed)),
                  const SizedBox(height: 12),
                ],
                for (final purchase in state.purchases)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PurchaseCard(purchase, paying: state.payingSaleId == purchase.id, onPay: () => _pay(purchase.id)),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard(this.purchase, {required this.paying, required this.onPay});
  final PurchaseUi purchase;
  final bool paying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: LucideIcons.receipt, background: AppColors.lavender, color: AppColors.electric, size: 40, iconSize: 18, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.receiptNumber == null ? 'Compra sin boleta' : 'Boleta ${purchase.receiptNumber}',
                      style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                    ),
                    Text('${purchase.date} · ${purchase.paymentMethod}', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(purchase.amount, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text(purchase.status, style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.electric)),
                ],
              ),
            ],
          ),
          if (purchase.paymentRejected) ...[
            const SizedBox(height: 10),
            Text('Tu último pago fue rechazado. Puedes intentarlo de nuevo.', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.errorRed)),
          ],
          if (purchase.payable) ...[
            const SizedBox(height: 12),
            SolidButton(
              label: paying ? 'Abriendo Mercado Pago…' : 'Pagar con tarjeta o Yape',
              height: 44,
              onPressed: paying ? null : onPay,
            ),
          ],
        ],
      ),
    );
  }
}
