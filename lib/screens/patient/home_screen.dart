import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

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
          _TryOnBanner(onTap: () => context.push('/p/tryon/verona')),
          const SizedBox(height: 24),
          SectionHeader('Próxima cita', action: 'Ver todas', onAction: () => context.go('/p/appointments')),
          const SizedBox(height: 8),
          if (next == null)
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
          Row(
            children: [
              Expanded(child: _Quick(icon: Icons.description_outlined, title: 'Mis recetas', footer: '2 activas', onTap: () => context.push('/p/prescription'))),
              const SizedBox(width: 12),
              Expanded(child: _Quick(icon: Icons.inventory_2_outlined, title: 'Mis pedidos', footer: '$activeOrders en camino', onTap: () => context.go('/p/orders'))),
              const SizedBox(width: 12),
              Expanded(child: _Quick(icon: Icons.favorite_border, title: 'Historial', footer: 'Último control', onTap: () => context.push('/p/history'))),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader('Armazones Destacados', action: 'Ver todos', onAction: () => context.push('/p/catalog')),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final id in const ['verona', 'havana']) ...[
                Expanded(child: _FrameCard(frameId: id)),
                if (id == 'verona') const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.wellnessBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.skyTint),
            ),
            child: Row(
              children: [
                const IconTile(icon: Icons.remove_red_eye_outlined, background: AppColors.wellnessIcon, color: AppColors.deepNavy, size: 44, iconSize: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Es hora de descansar la vista', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate600, height: 1.35),
                          children: const [
                            TextSpan(text: 'Aplica la regla '),
                            TextSpan(text: '20-20-20', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
                            TextSpan(text: ': cada 20 minutos mira a 6 metros por 20 segundos.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TryOnBanner extends StatelessWidget {
  const _TryOnBanner({required this.onTap});
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.teal700, borderRadius: BorderRadius.circular(99)),
                      child: Text('PRUEBA VIRTUAL', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                    const SizedBox(height: 6),
                    Text('Prueba tus lentes desde casa', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
                    const Spacer(),
                    Text('Usa nuestra cámara AR para ver cómo te quedan', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.periwinkle, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF14336F))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Pruébalo ahora', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.electric)),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.electric),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.title, required this.footer, required this.onTap});
  final IconData icon;
  final String title;
  final String footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconTile(icon: icon),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Text(footer, style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameCard extends StatelessWidget {
  const _FrameCard({required this.frameId});
  final String frameId;

  @override
  Widget build(BuildContext context) {
    final frame = DemoData.frame(frameId);
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
