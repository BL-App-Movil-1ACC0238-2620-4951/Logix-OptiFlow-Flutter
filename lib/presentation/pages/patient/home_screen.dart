import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/models.dart';
import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';
import 'home/featured_frames.dart';
import 'home/quick_access_row.dart';
import 'home/try_on_banner.dart';
import 'home/wellness_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<OptiFlowController>();
      if (app.session?.hasToken == true) app.refreshPatient();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final next = app.nextAppointment;
    final activeOrders = app.orders.where((o) => !o.delivered).length;
    return PatientScaffold(
      tab: PatientTab.home,
      topBar: ColoredBox(
        color: AppColors.patientHeader,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hola, ${app.firstName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.headerTitle, letterSpacing: -0.6),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/p/notifications'),
                    icon: Badge(
                      isLabelVisible: app.unreadCount > 0,
                      label: Text('${app.unreadCount}'),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TryOnBanner(onTap: () => context.push('/p/tryon/verona')),
          const SizedBox(height: 24),
          SectionHeader('Próxima cita', action: 'Ver todas', onAction: () => context.go('/p/appointments')),
          const SizedBox(height: 8),
          if (app.appointmentsLoading && next == null)
            const Center(child: CircularProgressIndicator())
          else if (app.appointmentsError != null && next == null)
            AppCard(child: Column(children: [Text(app.appointmentsError!), TextButton(onPressed: app.refreshAppointments, child: const Text('Reintentar'))]))
          else if (next == null)
            AppCard(
              onTap: () => context.push('/p/book'),
              child: Row(
                children: [
                  const IconTile(icon: Icons.calendar_month_outlined, color: AppColors.electric, size: 56, iconSize: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No tienes citas próximas', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        Text('Reserva tu evaluación visual', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.slate500),
                ],
              ),
            )
          else
            AppCard(
              radius: 24,
              onTap: () => context.push('/p/appointment/${next.id}'),
              child: Row(
                children: [
                  DateBadge(day: next.day, month: next.month),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusCapsule(next.status.label),
                        const SizedBox(height: 4),
                        Text(next.fromApi ? next.title : 'Evaluación visual integral', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        Text('${next.storeName} · ${next.time} hrs', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.slate500),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader('Accesos rápidos'),
          const SizedBox(height: 12),
          QuickAccessRow(
            activeOrders: activeOrders,
            onPrescriptions: () => context.push('/p/prescription'),
            onOrders: () => context.go('/p/orders'),
            onHistory: () => context.push('/p/history'),
          ),
          const SizedBox(height: 24),
          SectionHeader('Armazones Destacados', action: 'Ver todos', onAction: () => context.push('/p/catalog')),
          const SizedBox(height: 8),
          const FeaturedFrames(),
          const SizedBox(height: 20),
          const WellnessCard(),
        ],
      ),
    );
  }
}
