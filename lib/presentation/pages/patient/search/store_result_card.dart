import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/optical_store.dart';
import '../../../widgets/chrome.dart';

class StoreResultCard extends StatelessWidget {
  const StoreResultCard({super.key, required this.store});
  final OpticalStore store;

  @override
  Widget build(BuildContext context) {
    final rating = store.rating == null ? '—' : store.rating!.toStringAsFixed(1);
    final active = const {'ACTIVE', 'OPEN', 'ABIERTO'}.contains(store.status.toUpperCase());
    return AppCard(
      onTap: active ? () => context.push('/p/book?storeId=${store.id}') : null,
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
      borderColor: AppColors.skyTint,
      child: Row(
        children: [
          const IconTile(icon: Icons.remove_red_eye_outlined, background: AppColors.lavender, color: AppColors.navyBlue, size: 64, iconSize: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.skyTint, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.deepNavy),
                      const SizedBox(width: 4),
                      Text(active ? 'Consultar horarios' : 'No disponible', style: GoogleFonts.inter(fontSize: 12, color: AppColors.deepNavy)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: AppColors.navyBlue),
                    const SizedBox(width: 5),
                    Expanded(child: Text(store.address, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500))),
                  ],
                ),
                Text(store.rating == null ? 'Sin calificaciones' : '★ $rating', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.slate500, size: 20),
        ],
      ),
    );
  }
}
