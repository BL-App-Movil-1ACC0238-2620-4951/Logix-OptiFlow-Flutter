import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class BookingStoreStep extends StatelessWidget {
  const BookingStoreStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingVm = getIt<BookingViewModel>();
    return ListenableBuilder(
      listenable: bookingVm,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('Selecciona dónde quieres atenderte.', style: AppFonts.inter(fontSize: 14, color: AppColors.slate500)),
            ),
            const SizedBox(height: 20),
            if (bookingVm.state.loading && bookingVm.state.stores.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.electric))),
            for (var i = 0; i < bookingVm.state.stores.length; i++) ...[
              _StoreChoice(index: i, selected: bookingVm.state.selectedStoreIndex == i),
              const SizedBox(height: 12),
            ],
            if (bookingVm.state.error != null) ...[
              const SizedBox(height: 4),
              Text(bookingVm.state.error!, style: AppFonts.inter(fontSize: 13, color: AppColors.errorRed)),
              if (bookingVm.state.stores.isEmpty)
                TextButton(onPressed: bookingVm.state.loading ? null : () => bookingVm.prepareBooking(null, rescheduleId: bookingVm.state.reschedulingId), child: const Text('Reintentar')),
            ],
            const SizedBox(height: 8),
            SolidButton(
              label: 'Continuar',
              loading: bookingVm.state.loading,
              onPressed: bookingVm.state.stores.isEmpty ? null : bookingVm.continueFromStore,
            ),
          ],
        );
        },
    );
  }
}

class _StoreChoice extends StatelessWidget {
  const _StoreChoice({required this.index, required this.selected});
  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final store = getIt<BookingViewModel>().state.stores[index];
    return AppCard(
      onTap: () => getIt<BookingViewModel>().selectStore(index),
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
                Text(store.name, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 3),
                Text(store.address, style: AppFonts.inter(fontSize: 12, color: AppColors.slate500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 12, color: selected ? AppColors.electric : AppColors.slate500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [if (store.distance.isNotEmpty) store.distance, store.availability].join(' · '),
                        style: AppFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.electric : AppColors.slate500),
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
