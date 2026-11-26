import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/push/push_messaging.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/frame_image.dart';
import 'package:logix_optiflow/presentation/widgets/frame_photos.dart';

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
      if (getIt<SessionViewModel>().session?.hasToken == true) getIt<PatientViewModel>().refreshPatient();
      getIt<CatalogViewModel>().refreshCatalog();
      getIt<PushMessaging>().requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    final catalogVm = getIt<CatalogViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([patientVm, sessionVm, catalogVm]),
      builder: (context, _) {
        final next = patientVm.nextAppointment;
        final frames = catalogVm.state.frames;
        final featured = frames.take(2).toList();
        final prescriptions = patientVm.state.prescriptions.length;
        final activeOrders = patientVm.state.orders.where((o) => !o.delivered).length;
        return PatientScaffold(
          tab: PatientTab.home,
          topBar: ColoredBox(
            color: AppColors.patientHeader,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 85,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hola, ${sessionVm.firstName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.headerTitle, letterSpacing: -0.6),
                        ),
                      ),
                      BellButton(onTap: () => context.push('/p/notifications'), circle: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TryOnBanner(onTap: () {
                final frame = frames.where((f) => f.tryOnModelUrl != null).firstOrNull;
                context.push(frame == null ? '/p/catalog' : '/p/tryon/${Uri.encodeComponent(frame.id)}');
              }),
              const SizedBox(height: 24),
              SectionHeader('Próxima cita', action: 'Ver todas', onAction: () => context.go('/p/appointments')),
              const SizedBox(height: 12),
              if (next != null)
                _NextAppointmentCard(appointment: next, onTap: () => context.push('/p/appointment/${next.id}'))
              else
                _EmptyAppointmentCard(onTap: () => context.push('/p/book')),
              const SizedBox(height: 24),
              const SectionHeader('Accesos rápidos'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: _QuickAccess(
                      icon: LucideIcons.fileText,
                      title: 'Mis recetas',
                      onTap: () => context.push('/p/prescription'),
                      footer: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              switch (prescriptions) { 0 => 'Sin recetas', 1 => '1 receta', _ => '$prescriptions recetas' },
                              style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 11,
                    child: _QuickAccess(
                      icon: LucideIcons.package,
                      title: 'Mis pedidos',
                      onTap: () => context.go('/p/orders'),
                      footer: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(4)),
                        child: Text('$activeOrders en camino', style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 11,
                    child: _QuickAccess(
                      icon: LucideIcons.heart,
                      title: 'Historial',
                      onTap: () => context.push('/p/history'),
                      footer: Text('Último control', style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  children: [
                    Expanded(child: Text('Armazones Destacados', style: AppFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepNavy))),
                    GestureDetector(
                      onTap: () => context.push('/p/catalog'),
                      child: Text('Ver todos', style: AppFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.electric)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(
                      child: i < featured.length
                          ? _FeaturedFrame(frame: featured[i], onTap: () => context.push('/p/frame/${Uri.encodeComponent(featured[i].id)}'))
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const _WellnessWidget(),
            ],
          ),
        );
      },
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
              ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.teal700, borderRadius: BorderRadius.circular(100)),
                      child: Text('PRUEBA VIRTUAL', style: AppFonts.geist(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prueba tus lentes desde casa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Usa nuestra cámara AR para ver cómo te quedan',
                      style: AppFonts.openSansCondensed(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                bottom: 19,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.periwinkle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF14336F)),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Pruebalo ahora', style: AppFonts.openSansCondensed(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.electric)),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.electric),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment, required this.onTap});
  final AppointmentUi appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(17),
      onTap: onTap,
      // Altura mínima y no fija: con letra más grande el texto no cabe en 65 y se cortaría.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 65),
        child: Row(
          children: [
            DateBadge(day: appointment.day, month: appointment.month),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusCapsule(appointment.status.label),
                  const SizedBox(height: 4),
                  Text(
                    appointment.fromApi ? appointment.title : 'Evaluación visual integral',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          appointment.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('•', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate300)),
                      const SizedBox(width: 4),
                      Text('${appointment.time} hrs', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.slate500),
          ],
        ),
      ),
    );
  }
}

class _EmptyAppointmentCard extends StatelessWidget {
  const _EmptyAppointmentCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(17),
      onTap: onTap,
      child: SizedBox(
        height: 65,
        child: Row(
          children: [
            const IconTile(icon: LucideIcons.calendarPlus, background: AppColors.periwinkle, color: AppColors.electric, size: 56, iconSize: 24, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No tienes citas próximas', style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text('Reserva tu evaluación visual', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.slate500),
          ],
        ),
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.icon, required this.title, required this.footer, required this.onTap});
  final IconData icon;
  final String title;
  final Widget footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      borderColor: AppColors.cardBorder.withValues(alpha: 0.7),
      child: SizedBox(
        height: 97,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconTile(icon: icon, background: AppColors.periwinkle, color: AppColors.navyBlue),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy, height: 1.25)),
                const SizedBox(height: 4),
                footer,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedFrame extends StatelessWidget {
  const _FeaturedFrame({required this.frame, required this.onTap});
  final FrameItem frame;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = frame.shape?.toUpperCase() ?? 'MONTURA';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      borderColor: AppColors.cardBorder,
      child: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: FrameImage(path: framePhotoFor(frame.sku), height: 130)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shape, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.geist(fontSize: 12, color: AppColors.warmGray)),
                  const SizedBox(height: 4),
                  Text(frame.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.deepNavy)),
                  const SizedBox(height: 4),
                  Text('S/ ${frame.price.toStringAsFixed(2)}', style: AppFonts.openSansCondensed(fontSize: 14, color: AppColors.teal700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellnessWidget extends StatelessWidget {
  const _WellnessWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.wellnessBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint),
      ),
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.eye, background: AppColors.wellnessIcon, color: AppColors.deepNavy, size: 44, iconSize: 24, radius: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Es hora de descansar la vista', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate600, height: 1.375),
                    children: [
                      const TextSpan(text: 'Aplica la regla '),
                      TextSpan(text: '20-20-20', style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
                      const TextSpan(text: ': cada 20 minutos\nmira a 6 metros por 20 segundos.'),
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
