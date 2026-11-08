import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class BookingStoreStep extends StatelessWidget {
  const BookingStoreStep({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text('Selecciona dónde quieres atenderte.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500)),
        ),
        const SizedBox(height: 20),
        if (app.bookingLoading && app.bookingStores.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.electric))),
        for (var i = 0; i < app.bookingStores.length; i++) ...[
          _StoreChoice(index: i, selected: app.selectedStoreIndex == i),
          const SizedBox(height: 12),
        ],
        if (app.bookingError != null) ...[
          const SizedBox(height: 4),
          Text(app.bookingError!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.errorRed)),
        ],
        const SizedBox(height: 8),
        SolidButton(
          label: 'Continuar',
          onPressed: app.bookingStores.isEmpty ? null : app.continueFromStore,
        ),
      ],
    );
  }
}

class _StoreChoice extends StatelessWidget {
  const _StoreChoice({required this.index, required this.selected});
  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final store = context.read<OptiFlowController>().bookingStores[index];
    return AppCard(
      onTap: () => context.read<OptiFlowController>().selectStore(index),
      color: selected ? const Color(0xFFF7F8FF) : AppColors.white,
      borderColor: selected ? AppColors.electric : AppColors.lavender,
      borderWidth: selected ? 2 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? AppColors.electric : AppColors.slate300, width: selected ? 2 : 1),
            ),
            child: DecoratedBox(decoration: BoxDecoration(color: selected ? AppColors.electric : Colors.transparent, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 3),
                Text(store.address, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 12, color: selected ? AppColors.electric : AppColors.slate500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${store.distance} · ${store.availability}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.electric : AppColors.slate500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
