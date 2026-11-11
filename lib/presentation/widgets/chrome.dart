import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum PatientTab { home, search, appointments, orders, profile }

enum StaffTab { home, agenda, patients, inventory, more }

extension PatientTabX on PatientTab {
  String get label => switch (this) {
        PatientTab.home => 'Inicio',
        PatientTab.search => 'Buscar',
        PatientTab.appointments => 'Citas',
        PatientTab.orders => 'Pedidos',
        PatientTab.profile => 'Perfil',
      };

  String get path => switch (this) {
        PatientTab.home => '/p/home',
        PatientTab.search => '/p/search',
        PatientTab.appointments => '/p/appointments',
        PatientTab.orders => '/p/orders',
        PatientTab.profile => '/p/profile',
      };

  IconData get icon => switch (this) {
        PatientTab.home => Icons.home_rounded,
        PatientTab.search => Icons.visibility_outlined,
        PatientTab.appointments => Icons.calendar_month_outlined,
        PatientTab.orders => Icons.inventory_2_outlined,
        PatientTab.profile => Icons.person_outline_rounded,
      };
}

extension StaffTabX on StaffTab {
  String get label => switch (this) {
        StaffTab.home => 'Inicio',
        StaffTab.agenda => 'Citas',
        StaffTab.patients => 'Pacientes',
        StaffTab.inventory => 'Inventario',
        StaffTab.more => 'Más',
      };

  String get path => switch (this) {
        StaffTab.home => '/s/home',
        StaffTab.agenda => '/s/agenda',
        StaffTab.patients => '/s/patients',
        StaffTab.inventory => '/s/inventory',
        StaffTab.more => '/s/more',
      };

  IconData get icon => switch (this) {
        StaffTab.home => Icons.home_rounded,
        StaffTab.agenda => Icons.calendar_month_outlined,
        StaffTab.patients => Icons.groups_outlined,
        StaffTab.inventory => Icons.grid_view_rounded,
        StaffTab.more => Icons.more_horiz_rounded,
      };
}

class PatientScaffold extends StatelessWidget {
  const PatientScaffold({
    super.key,
    required this.tab,
    required this.topBar,
    required this.body,
    this.background = AppColors.screenBg,
  });

  final PatientTab? tab;
  final Widget topBar;
  final Widget body;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          topBar,
          Expanded(child: body),
          PatientBottomBar(selected: tab),
        ],
      ),
    );
  }
}

class StaffScaffold extends StatelessWidget {
  const StaffScaffold({
    super.key,
    required this.tab,
    required this.topBar,
    required this.body,
  });

  final StaffTab? tab;
  final Widget topBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          topBar,
          Expanded(child: body),
          StaffBottomBar(selected: tab),
        ],
      ),
    );
  }
}

class PatientBottomBar extends StatelessWidget {
  const PatientBottomBar({super.key, required this.selected});
  final PatientTab? selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final tab in PatientTab.values)
                  _TabButton(
                    label: tab.label,
                    icon: tab.icon,
                    active: tab == selected,
                    activeColor: AppColors.navy75,
                    inactiveColor: AppColors.navInactive,
                    activeBg: AppColors.skyTint,
                    onTap: () => context.go(tab.path),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StaffBottomBar extends StatelessWidget {
  const StaffBottomBar({super.key, required this.selected});
  final StaffTab? selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: AppColors.staffChip),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (final tab in StaffTab.values)
                    Expanded(
                      child: _TabButton(
                        label: tab.label,
                        icon: tab.icon,
                        active: tab == selected,
                        activeColor: AppColors.staffHeader,
                        inactiveColor: AppColors.staffMuted,
                        activeBg: AppColors.staffChip,
                        fontSize: 9,
                        onTap: () => context.go(tab.path),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeBg,
    required this.onTap,
    this.fontSize = 11,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBg;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 50,
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class DarkTopBar extends StatelessWidget {
  const DarkTopBar({super.key, required this.title, this.onBack, this.trailing, this.below});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.patientHeader,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      _BackButton(onTap: onBack!, light: true),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: -0.5),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
            if (below != null) below!,
          ],
        ),
      ),
    );
  }
}

class LightTopBar extends StatelessWidget {
  const LightTopBar({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (onBack != null) ...[
                  _BackButton(onTap: onBack!, light: false),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.patientHeader, letterSpacing: -0.6),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StaffTopBar extends StatelessWidget {
  const StaffTopBar({super.key, required this.title, this.onBack, this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.staffHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onTap: onBack!, light: true),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                    if (subtitle != null)
                      Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate300)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, required this.light});
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light ? AppColors.periwinkle : AppColors.backChip,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left_rounded, color: AppColors.patientHeader),
        ),
      ),
    );
  }
}

class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.background = AppColors.ctaNavy,
    this.foreground = AppColors.white,
    this.border,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color background;
  final Color foreground;
  final Color? border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.7),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: border == null ? BorderSide.none : BorderSide(color: border!),
          ),
        ),
        child: loading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: foreground)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18, color: foreground)],
                ],
              ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = AppColors.white, this.radius = 16});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8)),
        boxShadow: const [BoxShadow(color: Color(0x1400135B), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: card),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.background = AppColors.periwinkle, this.color = AppColors.navyBlue, this.size = 40, this.iconSize = 20});

  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepNavy))),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.electric)),
          ),
      ],
    );
  }
}

class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.day, required this.month});
  final String day;
  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.periwinkle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy, height: 1)),
          Text(month, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class StatusCapsule extends StatelessWidget {
  const StatusCapsule(this.label, {super.key, this.color = AppColors.emerald600, this.background = AppColors.emerald50});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
