import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/network/offline_cache.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';

// Componentes base copiados de Kotlin (Chrome.kt, Primitives.kt y PatientCommon.kt).

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
        PatientTab.home => LucideIcons.house,
        PatientTab.search => LucideIcons.glasses,
        PatientTab.appointments => LucideIcons.calendar,
        PatientTab.orders => LucideIcons.package,
        PatientTab.profile => LucideIcons.user,
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
        StaffTab.home => LucideIcons.house,
        StaffTab.agenda => LucideIcons.calendar,
        StaffTab.patients => LucideIcons.users,
        StaffTab.inventory => LucideIcons.layoutGrid,
        StaffTab.more => LucideIcons.ellipsis,
      };
}

/// Aviso de que no hay conexión y se muestran los datos guardados, con la fecha de su última actualización.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<OfflineCache>()) return const SizedBox.shrink();
    final cache = getIt<OfflineCache>();
    return ListenableBuilder(
      listenable: cache,
      builder: (context, _) {
        final date = cache.savedDataFrom;
        if (date == null) return const SizedBox.shrink();
        final label = DateFormat('d MMM, HH:mm', 'es').format(StoreTime.clock(date)).replaceAll('.', '');
        return Container(
          width: double.infinity,
          color: const Color(0xFF475569),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Sin conexión · datos actualizados el $label',
            textAlign: TextAlign.center,
            style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
          ),
        );
      },
    );
  }
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
          const OfflineBanner(),
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
    this.showBottomBar = true,
  });

  final StaffTab? tab;
  final Widget topBar;
  final Widget body;
  final bool showBottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          topBar,
          const OfflineBanner(),
          Expanded(child: body),
          if (showBottomBar) StaffBottomBar(selected: tab),
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
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
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
                    width: 64,
                    height: 50,
                    radius: 14,
                    spacing: 4,
                    labelStyle: AppFonts.geist(fontSize: 11, fontWeight: FontWeight.w500),
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
    final session = getIt<SessionViewModel>();
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: AppColors.staffChip),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 71,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    for (final tab in StaffTab.values)
                      if (session.canOpen(tab.path))
                        Expanded(
                          child: _TabButton(
                            label: tab.label,
                            icon: tab.icon,
                            active: tab == selected,
                            activeColor: AppColors.staffHeader,
                            inactiveColor: AppColors.staffMuted,
                            activeBg: AppColors.staffChip,
                            height: 57,
                            radius: 15,
                            spacing: 3,
                            labelStyle: AppFonts.inter(fontSize: 9, fontWeight: FontWeight.w600),
                            onTap: () => context.go(tab.path),
                          ),
                        ),
                  ],
                ),
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
    required this.height,
    required this.radius,
    required this.spacing,
    required this.labelStyle,
    required this.onTap,
    this.width,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBg;
  final double? width;
  final double height;
  final double radius;
  final double spacing;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: active ? activeBg : Colors.transparent, borderRadius: BorderRadius.circular(radius)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            SizedBox(height: spacing),
            Text(label, maxLines: 1, style: labelStyle.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Cabecera oscura del paciente con botón volver (Notificaciones, Mis citas, Receta…).
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
                      _SquareBack(onTap: onBack!, background: AppColors.periwinkle, radius: 12, iconSize: 22),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: -0.5),
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

/// Cabecera clara (Buscar, Explorar monturas, Perfil, Historial, Configuración).
class LightTopBar extends StatelessWidget {
  const LightTopBar({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (onBack != null) ...[
                _SquareBack(onTap: onBack!, background: AppColors.backChip, radius: 16, iconSize: 20),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.patientHeader, letterSpacing: -0.6),
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

class _SquareBack extends StatelessWidget {
  const _SquareBack({required this.onTap, required this.background, required this.radius, required this.iconSize});
  final VoidCallback onTap;
  final Color background;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
        child: Icon(LucideIcons.chevronLeft, size: iconSize, color: AppColors.patientHeader),
      ),
    );
  }
}

/// Campana del paciente con el punto de "sin leer".
class BellButton extends StatelessWidget {
  const BellButton({super.key, required this.onTap, this.dot = true, this.size = 42, this.circle = true});
  final VoidCallback onTap;
  final bool dot;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bellChip,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(LucideIcons.bell, size: 20, color: AppColors.patientHeader),
            if (dot) const Positioned(top: 7, right: 7, child: _Dot(size: 10, ring: 2)),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.ring});
  final double size;
  final double ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
      child: const DecoratedBox(decoration: BoxDecoration(color: AppColors.electric, shape: BoxShape.circle)),
    );
  }
}

/// Cabecera del personal. Con [onBack] es la cabecera con botón volver de Kotlin.
class StaffTopBar extends StatelessWidget {
  const StaffTopBar({super.key, required this.title, this.onBack, this.trailing, this.eyebrow});

  final String title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final back = onBack != null;
    return ColoredBox(
      color: AppColors.staffHeader,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 90,
          child: Padding(
            padding: back ? const EdgeInsets.symmetric(horizontal: 24) : const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              crossAxisAlignment: back ? CrossAxisAlignment.center : CrossAxisAlignment.end,
              children: [
                if (back) ...[
                  StaffCircleAction(icon: LucideIcons.chevronLeft, iconSize: 20, onTap: onBack!),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: back ? MainAxisAlignment.center : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Text(eyebrow!, style: AppFonts.inter(fontSize: back ? 10 : 9, fontWeight: FontWeight.w600, color: AppColors.staffSubtle, letterSpacing: back ? 1 : 1.17)),
                        if (!back) const SizedBox(height: 3),
                      ],
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: -0.6),
                      ),
                    ],
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

/// Campana del personal.
class StaffBell extends StatelessWidget {
  const StaffBell({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: AppColors.staffChip, shape: BoxShape.circle),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(LucideIcons.bell, size: 22, color: AppColors.staffHeader),
            Positioned(left: 27, top: 7, child: _Dot(size: 8, ring: 1)),
          ],
        ),
      ),
    );
  }
}

/// Botón redondo de la cabecera del personal.
class StaffCircleAction extends StatelessWidget {
  const StaffCircleAction({super.key, required this.icon, required this.onTap, this.iconSize = 22});
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: AppColors.staffChip, shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: AppColors.staffHeader),
      ),
    );
  }
}

/// Botón principal: Plus Jakarta Sans 16, alto 50 y radio 14.
class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.background = AppColors.electric,
    this.foreground = AppColors.white,
    this.border,
    this.icon,
    this.leadingIcon,
    this.height = 50,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color background;
  final Color foreground;
  final Color? border;

  /// Ícono después del texto.
  final IconData? icon;
  final IconData? leadingIcon;
  final double height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: enabled ? background : background.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border == null ? BorderSide.none : BorderSide(color: border!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !loading ? onPressed : null,
          child: Center(
            child: loading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leadingIcon != null) ...[Icon(leadingIcon, size: 18, color: foreground), const SizedBox(width: 10)],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (textStyle ?? AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)).copyWith(color: foreground),
                        ),
                      ),
                      if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 16, color: foreground)],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = AppColors.white, this.radius = 16, this.borderColor, this.borderWidth = 1});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.cardBorder.withValues(alpha: 0.8), width: borderWidth),
        boxShadow: const [BoxShadow(color: Color(0x141B3162), blurRadius: 16, offset: Offset(0, 6))],
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
  const IconTile({super.key, required this.icon, this.background = AppColors.periwinkle, this.color = AppColors.navyBlue, this.size = 40, this.iconSize = 20, this.radius = 12});

  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Píldora con ícono opcional (estados, etiquetas).
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.background,
    required this.color,
    this.icon,
    this.border,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    this.iconSize = 12,
  });

  final String text;
  final Color background;
  final Color color;
  final IconData? icon;
  final Color? border;
  final TextStyle? style;
  final EdgeInsets padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: iconSize, color: color), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (style ?? AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)).copyWith(color: color),
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy, letterSpacing: -0.4))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    Text(action!, style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.electric)),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.electric),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.day, required this.month, this.background = AppColors.periwinkle});
  final String day;
  final String month;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: AppFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: -0.5, height: 1.1)),
          Text(month, style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.electric, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

/// Estado de una cita como píldora, con su ícono.
class StatusCapsule extends StatelessWidget {
  const StatusCapsule(this.label, {super.key, this.color = AppColors.deepNavy, this.background, this.icon});
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final fallbackIcon = lower.contains('pendiente')
        ? LucideIcons.clock
        : lower.contains('cancel')
            ? LucideIcons.x
            : LucideIcons.check;
    return Pill(
      label,
      background: background ?? AppColors.skyTint.withValues(alpha: 0.5),
      color: color,
      icon: icon ?? fallbackIcon,
    );
  }
}

/// Selector tipo píldora (pestañas de filtros).
class SegmentChip extends StatelessWidget {
  const SegmentChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    required this.selectedBg,
    required this.selectedText,
    required this.unselectedText,
    this.unselectedBg = AppColors.white,
    this.border,
    this.style,
    this.height = 38,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBg;
  final Color selectedText;
  final Color unselectedBg;
  final Color unselectedText;
  final Color? border;
  final TextStyle? style;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(99),
          border: !selected && border != null ? Border.all(color: border!) : null,
        ),
        child: Text(
          text,
          maxLines: 1,
          style: (style ?? AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)).copyWith(color: selected ? selectedText : unselectedText),
        ),
      ),
    );
  }
}

/// Aviso de error en rojo suave; no muestra nada si [message] está vacío.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.errorRed)),
    );
  }
}

/// Mensaje breve al pie de la pantalla, como el Toast de Android que usa Kotlin.
void showAppMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xE6333333),
      elevation: 0,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(48, 0, 48, 72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
