import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class AuthField extends StatelessWidget {
  const AuthField({super.key, this.label, required this.controller, required this.hint, this.keyboard, this.obscure = false, this.trailing, this.fillColor = AppColors.mintWhite});

  final String? label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? trailing;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy, letterSpacing: -0.3)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.deepNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500),
            filled: true,
            fillColor: fillColor,
            isDense: true,
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.skyTint)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electric)),
          ),
        ),
      ],
    );
  }
}

class AuthTermsRow extends StatelessWidget {
  const AuthTermsRow({super.key, required this.accepted, required this.onToggle});
  final bool accepted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: accepted ? AppColors.electric : AppColors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accepted ? AppColors.electric : AppColors.deepNavy, width: 1.5),
            ),
            child: accepted ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500, height: 1.45),
                children: const [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(text: 'Términos de Servicio', style: TextStyle(color: AppColors.electric, fontWeight: FontWeight.w600)),
                  TextSpan(text: ' y la '),
                  TextSpan(text: 'Política de Privacidad', style: TextStyle(color: AppColors.electric, fontWeight: FontWeight.w600)),
                  TextSpan(text: ' de OptiFlow.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
