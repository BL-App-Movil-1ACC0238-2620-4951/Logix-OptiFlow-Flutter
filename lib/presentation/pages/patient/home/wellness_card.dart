import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../widgets/chrome.dart';

class WellnessCard extends StatelessWidget {
  const WellnessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wellnessBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint),
      ),
      child: Row(
        children: [
          const IconTile(icon: Icons.remove_red_eye_outlined, background: AppColors.wellnessIcon, color: AppColors.deepNavy, size: 44, iconSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Es hora de descansar la vista', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate600, height: 1.35),
                    children: const [
                      TextSpan(text: 'Aplica la regla '),
                      TextSpan(text: '20-20-20', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
                      TextSpan(text: ': cada 20 minutos mira a 6 metros por 20 segundos.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
