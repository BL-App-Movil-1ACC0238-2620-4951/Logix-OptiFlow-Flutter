import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
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
                child: Text(app.initials, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.electric)),
              ),
              const SizedBox(height: 14),
              Text(app.displayName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              Text(app.email, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
              const SizedBox(height: 12),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar perfil'),
                onPressed: () => _edit(context, app),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Mi salud visual', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Menu(icon: Icons.favorite_border, title: 'Historial clínico', subtitle: 'Controles y antecedentes', onTap: () => context.push('/p/history')),
                const Divider(height: 1, color: AppColors.lavender),
                _Menu(icon: Icons.description_outlined, title: 'Mis recetas', subtitle: '1 receta disponible', onTap: () => context.push('/p/prescription')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Cuenta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Menu(icon: Icons.settings_outlined, title: 'Configuración', onTap: () => context.push('/p/settings')),
                const Divider(height: 1, color: AppColors.lavender),
                _Menu(icon: Icons.help_outline, title: 'Ayuda y soporte', onTap: () => context.push('/p/settings')),
                const Divider(height: 1, color: AppColors.lavender),
                _Menu(icon: Icons.business_center_outlined, title: 'Vista personal de óptica', subtitle: 'Cambiar al rol de personal', onTap: () => context.go('/s/home')),
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
              await app.logout();
              if (context.mounted) context.go('/auth');
            },
          ),
          const SizedBox(height: 12),
          Text('Tus datos de demostración se guardan solo en este dispositivo.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, OptiFlowController app) async {
    final name = TextEditingController(text: app.displayName);
    final phone = TextEditingController(text: app.session?.phone ?? '');
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
    if (saved == true && app.session != null) {
      app.updateProfile(name: name.text, phone: phone.text);
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
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<OptiFlowController>().history;
    final latest = history.isEmpty ? '12 de marzo de 2025' : _prettyDate(history.first.date);
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
                      Text('Último control', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.75))),
                      Text(latest, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                      Text('Próximo control recomendado en 9 meses', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Atenciones', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 16),
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
                        Text(history[index].date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(history[index].title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        const SizedBox(height: 6),
                        Text(history[index].summary, style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500)),
                        const SizedBox(height: 14),
                        Text(history[index].professional, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
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
    final app = context.watch<OptiFlowController>();
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: LightTopBar(title: 'Configuración', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('Preferencias', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
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
                  value: app.settings.controlReminders,
                  onChanged: app.setControlReminders,
                  title: Text('Recordatorios de control', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
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
          Text('Aplicación', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
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
          Text('OptiFlow · Versión 1.0.0', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate300)),
        ],
      ),
    );
  }
}
