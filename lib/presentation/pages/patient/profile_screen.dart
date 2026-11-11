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
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: LightTopBar(title: 'Historial clínico', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final entry in history) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  Text(entry.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text(entry.summary, style: GoogleFonts.inter(color: AppColors.slate600)),
                  Text(entry.professional, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.staff = false});
  final bool staff;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool reminders = true;
  bool promos = false;
  bool biometrics = false;

  @override
  Widget build(BuildContext context) {
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: LightTopBar(title: widget.staff ? 'Configuración y permisos' : 'Configuración', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(value: reminders, onChanged: (v) => setState(() => reminders = v), title: const Text('Recordatorios de cita'), subtitle: const Text('Avisos antes de tu evaluación')),
          SwitchListTile(value: promos, onChanged: (v) => setState(() => promos = v), title: const Text('Ofertas y novedades'), subtitle: const Text('Promociones de monturas')),
          SwitchListTile(value: biometrics, onChanged: (v) => setState(() => biometrics = v), title: const Text('Bloqueo de la app'), subtitle: const Text('Pedir confirmación al abrir')),
          const SizedBox(height: 12),
          Text('OptiFlow Flutter · misma API que la app Android.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
        ],
      ),
    );
  }
}
