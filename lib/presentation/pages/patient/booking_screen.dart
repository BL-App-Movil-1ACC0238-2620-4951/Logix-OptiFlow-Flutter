import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';
import 'booking/confirm_step.dart';
import 'booking/date_step.dart';
import 'booking/done_step.dart';
import 'booking/store_step.dart';

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
      if (mounted) context.read<OptiFlowController>().prepareBooking(widget.storeId, rescheduleId: widget.rescheduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final title = switch (app.bookingStep) {
      1 => 'Elige una óptica',
      2 => 'Elige una fecha',
      _ => 'Confirma tu reserva',
    };
    return PatientScaffold(
      tab: PatientTab.appointments,
      topBar: DarkTopBar(
        title: title,
        onBack: () {
          if (app.bookingLoading) return;
          if (app.bookingAppointment != null && app.bookingStep != 4) {
            context.go('/p/appointments');
            return;
          }
          if (app.bookingStep > 1 && app.bookingStep < 4) {
            app.bookingBack();
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
          BookingStepper(step: app.bookingStep),
          const SizedBox(height: 26),
          if (app.reschedulingId != null && app.bookingStep < 4)
            const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Reservaremos el nuevo horario y después cancelaremos la cita anterior.')),
          if (app.bookingStep == 1) const BookingStoreStep(),
          if (app.bookingStep == 2) const BookingDateStep(),
          if (app.bookingStep == 3) const BookingConfirmStep(),
          if (app.bookingStep == 4) const BookingDoneStep(),
        ],
      ),
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
