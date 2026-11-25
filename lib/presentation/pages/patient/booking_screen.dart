import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/booking_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/pages/patient/booking/confirm_step.dart';
import 'package:logix_optiflow/presentation/pages/patient/booking/date_step.dart';
import 'package:logix_optiflow/presentation/pages/patient/booking/done_step.dart';
import 'package:logix_optiflow/presentation/pages/patient/booking/store_step.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.storeId, this.rescheduleId});
  final String? storeId;
  final String? rescheduleId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getIt<BookingViewModel>().prepareBooking(widget.storeId, rescheduleId: widget.rescheduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingVm = getIt<BookingViewModel>();
    return ListenableBuilder(
      listenable: bookingVm,
      builder: (context, _) {
        final title = switch (bookingVm.state.step) {
          1 => 'Elige una óptica',
          2 => 'Elige una fecha',
          _ => 'Confirma tu reserva',
        };
        return PatientScaffold(
          tab: PatientTab.appointments,
          topBar: DarkTopBar(
            title: title,
            onBack: () {
              if (bookingVm.state.loading) return;
              if (bookingVm.state.appointment != null && bookingVm.state.step != 4) {
                context.go('/p/appointments');
                return;
              }
              if (bookingVm.state.step > 1 && bookingVm.state.step < 4) {
                bookingVm.bookingBack();
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/p/home');
              }
            },
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
            children: [
              BookingStepper(step: bookingVm.state.step),
              const SizedBox(height: 26),
              if (bookingVm.state.reschedulingId != null && bookingVm.state.step < 4)
                const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Reservaremos el nuevo horario y después cancelaremos la cita anterior.')),
              if (bookingVm.state.step == 1) const BookingStoreStep(),
              if (bookingVm.state.step == 2) const BookingDateStep(),
              if (bookingVm.state.step == 3) const BookingConfirmStep(),
              if (bookingVm.state.step == 4) const BookingDoneStep(),
            ],
          ),
        );
        },
    );
  }
}

class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(color: AppColors.white, thickness: 2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 1; index <= 4; index++) _StepDot(index: index, step: step),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.step});
  final int index;
  final int step;

  @override
  Widget build(BuildContext context) {
    final done = index < step || step == 4;
    final current = index == step && step != 4;
    final active = done || current;
    final showCheck = done && !(step == 4 && index == 4);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.electric : AppColors.white,
        shape: BoxShape.circle,
        border: active ? null : Border.all(color: AppColors.slate300),
      ),
      child: showCheck
          ? const Icon(Icons.check, size: 14, color: AppColors.white)
          : Text('$index', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.white : AppColors.slate400)),
    );
  }
}
