import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class TryOnBanner extends StatelessWidget {
  const TryOnBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/img_banner_ar.png', fit: BoxFit.cover),
              Container(color: Colors.black38),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.teal700, borderRadius: BorderRadius.circular(99)),
                      child: Text('PRUEBA VIRTUAL', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                    const SizedBox(height: 6),
                    Text('Prueba tus lentes desde casa', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
                    const SizedBox(height: 18),
                    Text('Usa nuestra cámara AR para ver cómo te quedan', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                bottom: 19,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.periwinkle, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF14336F))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Pruébalo ahora', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.electric)),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.electric),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
