import 'package:flutter/material.dart';

/// Fuentes de Kotlin incluidas en la app (`assets/fonts`), sin descargas.
///
/// Inter, Plus Jakarta Sans, Geist y Open Sans son variables: el grosor se pide
/// con el eje `wght` además de [FontWeight].
abstract final class AppFonts {
  static TextStyle inter({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) =>
      _variable('Inter', fontSize, fontWeight, color, letterSpacing, height);

  static TextStyle plusJakartaSans({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) =>
      _variable('PlusJakartaSans', fontSize, fontWeight, color, letterSpacing, height);

  static TextStyle geist({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) =>
      _variable('Geist', fontSize, fontWeight, color, letterSpacing, height);

  /// "Open Sans Hebrew Condensed" del diseño: Open Sans con ancho 75.
  static TextStyle openSansCondensed({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) =>
      _variable('OpenSans', fontSize, fontWeight, color, letterSpacing, height, width: 75);

  static TextStyle poppins({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) => TextStyle(
        fontFamily: 'Poppins', fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, height: height,
      );

  /// Tema de texto de la app: Plus Jakarta Sans, como la tipografía base de Kotlin.
  static TextTheme textTheme(TextTheme base) {
    TextStyle? jakarta(TextStyle? style) => style?.copyWith(
          fontFamily: 'PlusJakartaSans',
          fontVariations: [FontVariation('wght', (style.fontWeight ?? FontWeight.w400).value.toDouble())],
        );
    return base.copyWith(
      displayLarge: jakarta(base.displayLarge), displayMedium: jakarta(base.displayMedium), displaySmall: jakarta(base.displaySmall),
      headlineLarge: jakarta(base.headlineLarge), headlineMedium: jakarta(base.headlineMedium), headlineSmall: jakarta(base.headlineSmall),
      titleLarge: jakarta(base.titleLarge), titleMedium: jakarta(base.titleMedium), titleSmall: jakarta(base.titleSmall),
      bodyLarge: jakarta(base.bodyLarge), bodyMedium: jakarta(base.bodyMedium), bodySmall: jakarta(base.bodySmall),
      labelLarge: jakarta(base.labelLarge), labelMedium: jakarta(base.labelMedium), labelSmall: jakarta(base.labelSmall),
    );
  }

  static TextStyle _variable(String family, double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height, {double? width}) {
    final weight = fontWeight ?? FontWeight.w400;
    return TextStyle(
      fontFamily: family, fontSize: fontSize, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height,
      fontVariations: [FontVariation('wght', weight.value.toDouble()), if (width != null) FontVariation('wdth', width)],
    );
  }
}
