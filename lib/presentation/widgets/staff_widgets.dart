import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

// Componentes del personal copiados de Kotlin (StaffCommon.kt).

/// Bloque oscuro de cabecera dentro del contenido.
class StaffHero extends StatelessWidget {
  const StaffHero({super.key, required this.child, this.background = AppColors.staffHeader, this.radius = 26, this.padding = const EdgeInsets.all(22)});
  final Widget child;
  final Color background;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

class StaffPill extends StatelessWidget {
  const StaffPill(this.text, {super.key, this.icon = LucideIcons.check, this.background = AppColors.staffBlue50, this.color = AppColors.staffBlue700, this.size = 9});
  final String text;
  final IconData? icon;
  final Color background;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pill(
      text,
      background: background,
      color: color,
      icon: icon,
      style: AppFonts.inter(fontSize: size, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      iconSize: 13,
    );
  }
}

class StaffSectionTitle extends StatelessWidget {
  const StaffSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk, letterSpacing: -0.16))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.staffAccent)),
          ),
      ],
    );
  }
}

/// Botón del personal: Inter 14 semibold sobre el azul de acento.
class StaffButton extends StatelessWidget {
  const StaffButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = AppColors.staffAccent,
    this.foreground = AppColors.white,
    this.border,
    this.loading = false,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SolidButton(
      label: label,
      onPressed: onPressed,
      leadingIcon: icon,
      background: background,
      foreground: foreground,
      border: border,
      loading: loading,
      height: height,
      textStyle: AppFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}

class StaffInitials extends StatelessWidget {
  const StaffInitials(this.text, {super.key, this.size = 43, this.background = AppColors.lavender, this.color = AppColors.electric, this.fontSize = 11});
  final String text;
  final double size;
  final Color background;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: AppFonts.inter(fontSize: fontSize, color: color)),
    );
  }
}

class StaffIconTile extends StatelessWidget {
  const StaffIconTile(this.icon, {super.key, this.size = 35, this.background = AppColors.periwinkle, this.color = AppColors.staffAccent, this.radius = 11});
  final IconData icon;
  final double size;
  final Color background;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => IconTile(icon: icon, size: size, background: background, color: color, radius: radius);
}

/// Etiqueta de un campo de formulario, con un texto opcional a la derecha.
class StaffLabel extends StatelessWidget {
  const StaffLabel(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: AppFonts.inter(fontSize: 13, color: AppColors.staffInk)),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(trailing!, textAlign: TextAlign.end, style: AppFonts.inter(fontSize: 11, color: AppColors.staffAccent)),
          ),
      ],
    );
  }
}

/// Campo de texto del personal: fondo claro, borde gris y radio 14.
class StaffInput extends StatelessWidget {
  const StaffInput({
    super.key,
    required this.controller,
    required this.placeholder,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final single = maxLines == 1;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.slate200));
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      cursorColor: AppColors.staffAccent,
      style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.staffField,
        hintText: placeholder,
        hintStyle: AppFonts.inter(fontSize: single ? 14 : 12, color: AppColors.slate400),
        prefixIcon: icon == null ? null : Icon(icon, size: 20, color: AppColors.staffInk),
        suffixIcon: trailing,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: single ? 15 : 12),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.staffAccent)),
      ),
    );
  }
}

/// Fila que abre una lista para elegir (paciente, horario, proveedor…).
class StaffSelect extends StatelessWidget {
  const StaffSelect({super.key, required this.text, required this.onTap, this.icon, this.leading});
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.staffField,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)]
            else if (icon != null) ...[Icon(icon, size: 20, color: AppColors.staffInk), const SizedBox(width: 12)],
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 14, color: AppColors.staffInk))),
            const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.staffInk),
          ],
        ),
      ),
    );
  }
}

/// Botón flotante "+ acción" del personal.
class StaffFab extends StatelessWidget {
  const StaffFab({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: AppColors.staffAccent,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [BoxShadow(color: AppColors.staffAccent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.plus, size: 22, color: AppColors.white),
            const SizedBox(width: 10),
            Text(text, style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

/// Filtro tipo píldora del personal.
class StaffChip extends StatelessWidget {
  const StaffChip(this.text, {super.key, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.staffAccent : AppColors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.staffAccent : AppColors.staffBorder),
        ),
        child: Text(text, maxLines: 1, style: AppFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? AppColors.white : AppColors.staffInk)),
      ),
    );
  }
}

/// Fila "etiqueta ........ valor".
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.labelSize = 11, this.valueSize = 11});
  final String label;
  final String value;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppFonts.inter(fontSize: labelSize, color: AppColors.staffInk))),
          Text(value, style: AppFonts.inter(fontSize: valueSize, color: AppColors.staffInk)),
        ],
      ),
    );
  }
}
