import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class FeaturedFrames extends StatelessWidget {
  const FeaturedFrames({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final id in const ['verona', 'havana']) ...[
          Expanded(child: _FrameCard(frameId: id)),
          if (id == 'verona') const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _FrameCard extends StatelessWidget {
  const _FrameCard({required this.frameId});
  final String frameId;

  @override
  Widget build(BuildContext context) {
    final frame = context.watch<OptiFlowController>().frameById(frameId);
    return AppCard(
      onTap: () => context.push('/p/frame/$frameId'),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(frame.image, height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(frame.category, style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGray)),
                Text(frame.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.deepNavy)),
                Text('\$${frame.price}.00', style: GoogleFonts.inter(fontSize: 14, color: AppColors.teal700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
