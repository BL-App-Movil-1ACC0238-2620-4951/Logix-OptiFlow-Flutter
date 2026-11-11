import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../widgets/chrome.dart';

class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({super.key, required this.activeOrders, required this.onPrescriptions, required this.onOrders, required this.onHistory});
  final int activeOrders;
  final VoidCallback onPrescriptions;
  final VoidCallback onOrders;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Quick(
            icon: Icons.description_outlined,
            title: 'Mis recetas',
            onTap: onPrescriptions,
            footer: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('2 activas', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Quick(
            icon: Icons.inventory_2_outlined,
            title: 'Mis pedidos',
            onTap: onOrders,
            footer: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(4)),
              child: Text('$activeOrders en camino', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Quick(
            icon: Icons.favorite_border,
            title: 'Historial',
            onTap: onHistory,
            footer: Text('Último control', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
          ),
        ),
      ],
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.title, required this.footer, required this.onTap});
  final IconData icon;
  final String title;
  final Widget footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconTile(icon: icon),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                footer,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
