import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_account_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    final accountVm = getIt<PatientAccountViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([patientVm, sessionVm, accountVm]),
      builder: (context, _) {
        final account = accountVm.state;
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: LightTopBar(
            title: 'Mi Perfil',
            onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
            trailing: GestureDetector(
              onTap: () => context.push('/p/settings'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: const Color(0xFFE4E9FB), borderRadius: BorderRadius.circular(14)),
                child: const Icon(LucideIcons.settings, size: 20, color: AppColors.patientHeader),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(24)),
                    child: Text(sessionVm.initials, style: AppFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.electric)),
                  ),
                  const SizedBox(height: 18),
                  Text(sessionVm.displayName, textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  const SizedBox(height: 4),
                  Text(sessionVm.email, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.push('/p/profile/edit'),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.pencil, size: 14, color: AppColors.deepNavy),
                          const SizedBox(width: 8),
                          Text('Editar perfil', style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _PointsCard(account.points),
              const SizedBox(height: 22),
              Text('Mi salud visual', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
              const SizedBox(height: 10),
              MenuGroup(children: [
                MenuRow(icon: LucideIcons.heart, title: 'Historial clínico', subtitle: 'Controles y antecedentes', onTap: () => context.push('/p/history')),
                MenuRow(
                  icon: LucideIcons.fileText,
                  title: 'Mis recetas',
                  subtitle: switch (patientVm.state.prescriptions.length) { 0 => 'Aún no tienes recetas', 1 => '1 receta disponible', final n => '$n recetas disponibles' },
                  onTap: () => context.push('/p/prescriptions'),
                ),
              ]),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Cuenta', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
              ),
              const SizedBox(height: 10),
              MenuGroup(children: [
                MenuRow(
                  icon: LucideIcons.receipt,
                  title: 'Mis compras',
                  subtitle: account.loading
                      ? 'Consultando...'
                      : switch (account.purchases.length) { 0 => 'Aún no tienes compras', 1 => '1 compra', final n => '$n compras' },
                  onTap: () => context.push('/p/purchases'),
                ),
                MenuRow(icon: LucideIcons.settings, title: 'Configuración', onTap: () => context.push('/p/settings')),
                MenuRow(icon: LucideIcons.circleQuestionMark, title: 'Ayuda y soporte', onTap: () => context.push('/p/info/help')),
              ]),
              const SizedBox(height: 18),
              SolidButton(
                label: 'Cerrar sesión',
                background: AppColors.white,
                foreground: AppColors.electric,
                border: AppColors.skyTint,
                height: 46,
                onPressed: () async {
                  await sessionVm.logout();
                  if (context.mounted) context.go('/auth');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard(this.points);
  final int? points;

  @override
  Widget build(BuildContext context) {
    final soft = AppColors.white.withValues(alpha: 0.8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: AppColors.patientHeader, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.star, size: 20, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mis puntos OptiFlow', style: AppFonts.plusJakartaSans(fontSize: 13, color: soft)),
                Text(points == null ? 'Consultando...' : '$points puntos', style: AppFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
              ],
            ),
          ),
          Text('+100 en tu\ncumpleaños', textAlign: TextAlign.end, style: AppFonts.plusJakartaSans(fontSize: 11, color: soft)),
        ],
      ),
    );
  }
}

/// Grupo de opciones con borde, separadas por una línea.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.lavender,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.lavender),
            child,
          ],
        ],
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.showArrow = true});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            IconTile(icon: icon, background: AppColors.periwinkle, color: AppColors.navyBlue, size: 40, iconSize: 20, radius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  if (subtitle != null) Text(subtitle!, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                ],
              ),
            ),
            if (showArrow) const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.slate500),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    return ListenableBuilder(
      listenable: patientVm,
      builder: (context, _) {
        final history = patientVm.state.history;
        final latest = history.firstOrNull;
        final soft = AppColors.white.withValues(alpha: 0.75);
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: LightTopBar(title: 'Historial clínico', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x3300135B), blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    IconTile(icon: LucideIcons.eye, background: AppColors.white.withValues(alpha: 0.15), color: AppColors.white, size: 48, iconSize: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Último control', style: AppFonts.plusJakartaSans(fontSize: 12, color: soft)),
                          Text(
                            latest == null ? 'Sin controles registrados' : _prettyDate(latest.date),
                            style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                          if (latest != null)
                            Text('Próximo control recomendado en 9 meses', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Atenciones', style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 16),
              if (history.isEmpty)
                Text('Aún no tienes atenciones registradas.', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
              for (var index = 0; index < history.length; index++)
                InkWell(
                  onTap: () => context.push('/p/prescription'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 16,
                        child: Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(color: AppColors.electric, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                            ),
                            Container(width: 2, height: index == history.length - 1 ? 84 : 118, color: AppColors.lavender),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(history[index].date, style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Text(history[index].title, style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            const SizedBox(height: 6),
                            Text(history[index].summary, style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500)),
                            const SizedBox(height: 14),
                            Text(history[index].professional, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: AppColors.deepNavy, size: 20),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _prettyDate(String upper) {
    const months = {
      'ENE': 'enero',
      'FEB': 'febrero',
      'MAR': 'marzo',
      'ABR': 'abril',
      'MAY': 'mayo',
      'JUN': 'junio',
      'JUL': 'julio',
      'AGO': 'agosto',
      'SEP': 'septiembre',
      'SET': 'septiembre',
      'OCT': 'octubre',
      'NOV': 'noviembre',
      'DIC': 'diciembre',
    };
    final parts = upper.split(' ');
    if (parts.length != 3) return upper;
    final day = int.tryParse(parts[0])?.toString() ?? parts[0];
    return '$day de ${months[parts[1]] ?? parts[1].toLowerCase()} de ${parts[2]}';
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.staff = false});
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: sessionVm,
      builder: (context, _) {
        if (staff) {
          return StaffScaffold(
            tab: StaffTab.more,
            topBar: StaffTopBar(title: 'Mi cuenta', onBack: () => context.pop()),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionVm.displayName, style: Theme.of(context).textTheme.titleLarge),
                    Text(sessionVm.session?.email ?? ''),
                    const SizedBox(height: 8),
                    Text(sessionVm.session?.role.label ?? ''),
                    const SizedBox(height: 8),
                    const Text('El administrador de la óptica gestiona tu cuenta y tus permisos.'),
                  ],
                )),
                const SizedBox(height: 20),
                SolidButton(label: 'Cerrar sesión', icon: Icons.logout, onPressed: () async { await sessionVm.logout(); }),
              ],
            ),
          );
        }
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: LightTopBar(title: 'Configuración', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Preferencias', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ),
              const SizedBox(height: 10),
              MenuGroup(children: [
                MenuRow(icon: LucideIcons.bell, title: 'Notificaciones', subtitle: 'Citas, pedidos y recordatorios', onTap: () => context.push('/p/notifications')),
                MenuRow(icon: LucideIcons.lock, title: 'Privacidad y seguridad', onTap: () => context.push('/p/info/privacy')),
                MenuRow(icon: LucideIcons.circleQuestionMark, title: 'Ayuda y documentación', onTap: () => context.push('/p/info/help')),
              ]),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Aplicación', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ),
              const SizedBox(height: 10),
              MenuGroup(children: [
                // La app solo está en español: se muestra como dato, sin flecha.
                const MenuRow(icon: LucideIcons.settings, title: 'Idioma', subtitle: 'Español', showArrow: false),
                MenuRow(icon: LucideIcons.fileText, title: 'Términos y privacidad', onTap: () => context.push('/p/info/terms')),
              ]),
              const SizedBox(height: 36),
              Text('OptiFlow · Versión 1.0.0', textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate300)),
            ],
          ),
        );
      },
    );
  }
}
