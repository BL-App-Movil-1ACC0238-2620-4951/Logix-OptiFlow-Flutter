import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/patient_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/purchases_view_model.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientVm = getIt<PatientViewModel>();
    final sessionVm = getIt<SessionViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([patientVm, sessionVm]),
      builder: (context, _) {
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: LightTopBar(
            title: 'Mi Perfil',
            onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
            trailing: IconButton(onPressed: () => context.push('/p/settings'), icon: const Icon(Icons.settings_outlined, color: AppColors.patientHeader)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(24)),
                    child: Text(sessionVm.initials, style: AppFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.electric)),
                  ),
                  const SizedBox(height: 14),
                  Text(sessionVm.displayName, style: AppFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text(sessionVm.email, style: AppFonts.inter(fontSize: 13, color: AppColors.slate500)),
                  const SizedBox(height: 12),
                  ActionChip(
                    avatar: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar perfil'),
                    onPressed: () => _edit(context, sessionVm),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Mi salud visual', style: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Menu(icon: Icons.favorite_border, title: 'Historial clínico', subtitle: 'Controles y antecedentes', onTap: () => context.push('/p/history')),
                    const Divider(height: 1, color: AppColors.lavender),
                    _Menu(icon: Icons.description_outlined, title: 'Mis recetas', subtitle: switch (patientVm.state.prescriptions.length) { 0 => 'Aún no tienes recetas', 1 => '1 receta disponible', final n => '$n recetas disponibles' }, onTap: () => context.push('/p/prescriptions')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Cuenta', style: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListenableBuilder(
                      listenable: getIt<PurchasesViewModel>(),
                      builder: (context, _) {
                        final purchases = getIt<PurchasesViewModel>().state;
                        return _Menu(
                          icon: Icons.receipt_long_outlined,
                          title: 'Mis compras',
                          subtitle: purchases.loading
                              ? 'Consultando...'
                              : switch (purchases.purchases.length) { 0 => 'Aún no tienes compras', 1 => '1 compra', final n => '$n compras' },
                          onTap: () => context.push('/p/purchases'),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.lavender),
                    _Menu(icon: Icons.settings_outlined, title: 'Configuración', onTap: () => context.push('/p/settings')),
                    const Divider(height: 1, color: AppColors.lavender),
                    _Menu(icon: Icons.help_outline, title: 'Ayuda y soporte', onTap: () => context.push('/p/settings')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SolidButton(
                label: 'Cerrar sesión',
                background: AppColors.white,
                foreground: AppColors.electric,
                border: AppColors.skyTint,
                onPressed: () async {
                  await sessionVm.logout();
                  if (context.mounted) context.go('/auth');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
        },
    );
  }

  Future<void> _edit(BuildContext context, SessionViewModel sessionVm) async {
    final name = TextEditingController(text: sessionVm.displayName);
    final phone = TextEditingController(text: sessionVm.session?.phone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && sessionVm.session != null) {
      sessionVm.updateProfile(name: name.text, phone: phone.text);
    }
    name.dispose();
    phone.dispose();
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconTile(icon: icon),
      title: Text(title, style: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
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
        final latest = history.isEmpty ? 'Sin controles registrados' : _prettyDate(history.first.date);
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: LightTopBar(title: 'Historial clínico', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(color: AppColors.navyBlue, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x3300135B), blurRadius: 12, offset: Offset(0, 6))]),
                child: Row(
                  children: [
                    IconTile(icon: Icons.remove_red_eye_outlined, background: AppColors.white.withValues(alpha: 0.15), color: AppColors.white, size: 48, iconSize: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Último control', style: AppFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.75))),
                          Text(latest, style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                          Text('Se recomienda un control al año', style: AppFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
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
                Text('Aún no tienes atenciones registradas.', style: AppFonts.inter(fontSize: 14, color: AppColors.slate500)),
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
                            Text(history[index].date, style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Text(history[index].title, style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            const SizedBox(height: 6),
                            Text(history[index].summary, style: AppFonts.inter(fontSize: 14, color: AppColors.slate500)),
                            const SizedBox(height: 14),
                            Text(history[index].professional, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.deepNavy, size: 20),
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
              Text('Preferencias', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Menu(
                      icon: Icons.notifications_none,
                      title: 'Notificaciones',
                      subtitle: 'Citas, pedidos y recordatorios',
                      onTap: () => context.push(staff ? '/s/alerts' : '/p/notifications'),
                    ),
                    const Divider(height: 1, color: AppColors.lavender),
                    SwitchListTile(
                      value: sessionVm.state.settings.controlReminders,
                      onChanged: sessionVm.setControlReminders,
                      title: Text('Recordatorios de control', style: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      subtitle: const Text('Avisos preventivos de salud visual'),
                    ),
                    const Divider(height: 1, color: AppColors.lavender),
                    _Menu(icon: Icons.lock_outline, title: 'Privacidad y seguridad', onTap: () {}),
                    const Divider(height: 1, color: AppColors.lavender),
                    _Menu(icon: Icons.help_outline, title: 'Ayuda y documentación', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Aplicación', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Menu(icon: Icons.language, title: 'Idioma', subtitle: 'Español', onTap: () {}),
                    const Divider(height: 1, color: AppColors.lavender),
                    _Menu(icon: Icons.description_outlined, title: 'Términos y privacidad', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text('OptiFlow · Versión 1.0.0', textAlign: TextAlign.center, style: AppFonts.inter(fontSize: 12, color: AppColors.slate300)),
            ],
          ),
        );
        },
    );
  }
}
