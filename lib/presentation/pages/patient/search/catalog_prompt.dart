import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class CatalogPrompt extends StatelessWidget {
  const CatalogPrompt({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.infoBanner, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.skyTint)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
              child: Text('?', style: GoogleFonts.poppins(fontSize: 24, color: AppColors.deepNavy)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿YA SABES QUÉ TE GUSTA?', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.4)),
                  Text('Busca por montura', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text('Elige un modelo y descubre dónde está disponible.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate500),
          ],
        ),
      ),
    );
  }
}
