import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({super.key, required this.register, required this.onChanged});
  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.periwinkle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _chip('Iniciar sesión', !register, () => onChanged(false)),
          _chip('Registrarme', register, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? const [BoxShadow(color: Color(0x1400135B), blurRadius: 2, offset: Offset(0, 1))] : null,
          ),
          child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.deepNavy : AppColors.slate500)),
        ),
      ),
    );
  }
}

class AuthRoleCard extends StatelessWidget {
  const AuthRoleCard({super.key, required this.letter, required this.title, required this.description, required this.selected, required this.onTap});
  final String letter;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.periwinkle : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.electric : AppColors.slate200, width: selected ? 2 : 1),
          boxShadow: selected ? const [BoxShadow(color: Color(0x240013C1), blurRadius: 8, offset: Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected ? AppColors.lavender : AppColors.periwinkle, borderRadius: BorderRadius.circular(12)),
              child: Text(letter, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? AppColors.electric : AppColors.navyBlue)),
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.deepNavy : AppColors.slate700, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: selected ? AppColors.slate500 : AppColors.slate400)),
          ],
        ),
      ),
    );
  }
}
