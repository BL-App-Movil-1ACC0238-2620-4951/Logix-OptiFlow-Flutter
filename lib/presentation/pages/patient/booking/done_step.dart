import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../state/optiflow_controller.dart';
import '../../../widgets/chrome.dart';

class BookingDoneStep extends StatelessWidget {
  const BookingDoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final slot = app.selectedSlot;
    final store = app.bookingStores.isEmpty ? null : app.bookingStores[app.selectedStoreIndex];
    final date = slot?.date;
    final weekday = date == null ? '' : DateFormat('E', 'es').format(date).replaceAll('.', '').toUpperCase();
    final month = date == null ? '' : DateFormat('MMMM', 'es').format(date).toUpperCase();
    final place = store == null ? '' : (store.id != null ? store.name : 'Óptica Visión Norte · ${store.name}');
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lavender))),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE6EBFD), border: Border.all(color: AppColors.lavender)),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.electric),
                child: const Icon(Icons.check, color: AppColors.white, size: 30),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Text('RESERVA ENVIADA', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text('Tu horario fue reservado', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'La óptica revisará la solicitud y te notificará el tipo de atención.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500, height: 1.5),
          ),
        ),
        const SizedBox(height: 22),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    Text(weekday, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                    Text('${date?.day ?? ''}', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                    Text(month, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(height: 56, child: _Dash()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 12, color: AppColors.electric),
                          const SizedBox(width: 4),
                          Text('Pendiente de confirmación', style: GoogleFonts.inter(fontSize: 11, color: AppColors.electric)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${slot?.label ?? ''} · Cita en óptica', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SolidButton(
          label: 'Ver mis citas',
          onPressed: () {
            context.read<OptiFlowController>().refreshPatient();
            context.go('/p/appointments');
          },
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => context.go('/p/home'),
          child: Text('Volver al inicio', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.electric)),
        ),
      ],
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(1, 56), painter: _DashPainter());
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lavender
      ..strokeWidth = 2;
    const dash = 6.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash), paint);
      y += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
