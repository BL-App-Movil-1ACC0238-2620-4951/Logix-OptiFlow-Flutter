import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:logix_optiflow/features/inventory/domain/frame.dart';

/// Modelos de prueba virtual que la app sabe dibujar; el backend los indica en `tryOnModelUrl` (p. ej. `try-on/aviator`).
enum TryOnStyle { rectangular, oval, aviator, browline, square }

/// Modelo de prueba de la montura, o null si no tiene (entonces no se ofrece "Probar").
TryOnStyle? tryOnStyleOf(FrameItem frame) {
  final url = frame.tryOnModelUrl;
  if (url == null) return null;
  final key = url.split('/').last.split('.').first.toLowerCase();
  return TryOnStyle.values.where((s) => s.name == key).firstOrNull ?? TryOnStyle.rectangular;
}

/// Acabado del armazón: color base y si es de metal (brillo) o carey (moteado).
class FrameFinish {
  const FrameFinish(this.base, {required this.metal, required this.tortoise});

  final Color base;
  final bool metal;
  final bool tortoise;
}

/// Acabado aproximado según el color y el material del catálogo.
FrameFinish tryOnFinishOf(FrameItem frame) {
  final name = (frame.color ?? '').toLowerCase();
  final material = (frame.material ?? '').toLowerCase();
  final metal = material.contains('metal') && !material.contains('acetato');
  if (name.contains('carey') || name.contains('havana')) return const FrameFinish(Color(0xFF5C3317), metal: false, tortoise: true);
  if (name.contains('dorado')) return const FrameFinish(Color(0xFFC9A227), metal: true, tortoise: false);
  if (name.contains('plat')) return const FrameFinish(Color(0xFFB8BEC6), metal: true, tortoise: false);
  if (name.contains('negro')) return FrameFinish(const Color(0xFF151515), metal: metal, tortoise: false);
  if (name.contains('transparente')) return const FrameFinish(Color(0xCCDCE3EC), metal: false, tortoise: false);
  return FrameFinish(const Color(0xFF14254F), metal: metal, tortoise: false);
}

const _silver = FrameFinish(Color(0xFFC4C9D0), metal: true, tortoise: false);

/// Centro de los dos ojos del rostro detectado, en píxeles de la vista de la cámara, y el giro de la cara en grados.
class EyePositions {
  const EyePositions(this.left, this.right, [this.yaw = 0]);

  final Offset left;
  final Offset right;
  final double yaw;

  /// Mitad de camino hacia [next], para que la montura no tiemble.
  EyePositions towards(EyePositions next) =>
      EyePositions(Offset.lerp(left, next.left, 0.5)!, Offset.lerp(right, next.right, 0.5)!, (yaw + next.yaw) / 2);
}

/// Dibuja la montura sobre los ojos: se centra entre ambos, escala con su distancia, gira con la
/// inclinación de la cabeza y se angosta al girar la cara hacia un lado ([EyePositions.yaw]).
class GlassesPainter extends CustomPainter {
  const GlassesPainter(this.style, this.finish, this.eyes);

  final TryOnStyle style;
  final FrameFinish finish;
  final EyePositions? eyes;

  @override
  void paint(Canvas canvas, Size size) {
    final eyes = this.eyes;
    if (eyes == null) return;
    final (a, b) = eyes.left.dx <= eyes.right.dx ? (eyes.left, eyes.right) : (eyes.right, eyes.left);
    // Al girar la cara los ojos se acercan en pantalla; se usa el ancho real y luego se comprime.
    final turn = math.cos(eyes.yaw.clamp(-50, 50) * math.pi / 180);
    final d = (b - a).distance / turn;
    if (d < 1) return;
    final center = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final lensW = d * 0.8;
    final lensH = lensW *
        switch (style) {
          TryOnStyle.rectangular => 0.5,
          TryOnStyle.oval => 0.7,
          TryOnStyle.aviator => 0.85,
          TryOnStyle.browline => 0.6,
          TryOnStyle.square => 0.8,
        };
    final offsetX = d * 0.55;
    final lensY = center.dy + d * 0.05;
    final top = lensY - lensH / 2;
    final rim = d * (finish.metal ? 0.035 : 0.075);
    final lenses = [for (final side in const [-1.0, 1.0]) _lensPath(center.dx + side * offsetX, lensY, lensW, lensH, side)];
    final bounds = Rect.fromLTRB(center.dx - offsetX - lensW / 2, top, center.dx + offsetX + lensW / 2, top + lensH);
    final frameShader = _finishShader(finish, bounds, d);
    final inner = offsetX - lensW / 2;
    final bridge = Path()
      ..moveTo(center.dx - inner, top + lensH * 0.3)
      ..quadraticBezierTo(center.dx, top + lensH * 0.08, center.dx + inner, top + lensH * 0.3);

    Paint stroke(double width, {Shader? shader, Color? color, StrokeCap cap = StrokeCap.butt}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..isAntiAlias = true
      ..shader = shader
      ..color = color ?? const Color(0xFF000000);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));
    canvas.scale(turn, 1);
    canvas.translate(-center.dx, -center.dy);

    // Sombra suave del armazón sobre la piel.
    canvas.save();
    canvas.translate(0, d * 0.05);
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.035 / 2);
    for (final lens in lenses) {
      canvas.drawPath(lens, shadow..strokeWidth = rim * 1.2);
    }
    canvas.drawPath(bridge, shadow..strokeWidth = rim);
    canvas.restore();

    // Patillas: salen de la bisagra y se pierden hacia las orejas.
    for (final side in const [-1.0, 1.0]) {
      final hinge = Offset(center.dx + side * (offsetX + lensW / 2), top + lensH * 0.2);
      final end = Offset(hinge.dx + side * d * 0.3, hinge.dy - lensH * 0.04);
      canvas.drawLine(hinge, end, stroke(rim * 0.9, shader: _linear([finish.base, finish.base.withValues(alpha: 0)], hinge, end), cap: StrokeCap.round));
    }
    for (final lens in lenses) {
      _drawLens(canvas, lens, lensW, sun: style == TryOnStyle.aviator);
    }
    if (style == TryOnStyle.browline) {
      // Aro inferior de metal fino y ceja gruesa de acetato arriba.
      final metalShader = _finishShader(_silver, bounds, d);
      for (final lens in lenses) {
        canvas.drawPath(lens, stroke(d * 0.025, shader: metalShader));
      }
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(bounds.left - d, top - d, bounds.right + d, top + lensH * 0.4));
      for (final lens in lenses) {
        canvas.drawPath(lens, stroke(d * 0.13, shader: frameShader));
      }
      canvas.restore();
    } else {
      for (final lens in lenses) {
        canvas.drawPath(lens, stroke(rim, shader: frameShader));
      }
    }
    // Borde de luz en la parte superior del aro.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(bounds.left - d, top - d, bounds.right + d, top + lensH * 0.3));
    for (final lens in lenses) {
      canvas.drawPath(lens, stroke(rim * 0.22, color: Colors.white.withValues(alpha: 0.28)));
    }
    canvas.restore();
    canvas.drawPath(
      bridge,
      stroke(rim, shader: style == TryOnStyle.browline ? _finishShader(_silver, bounds, d) : frameShader, cap: StrokeCap.round),
    );
    if (style == TryOnStyle.aviator) {
      final y = top + rim / 2;
      canvas.drawLine(Offset(center.dx - inner, y), Offset(center.dx + inner, y), stroke(rim * 0.8, shader: frameShader, cap: StrokeCap.round));
    }
    if (finish.metal || style == TryOnStyle.browline) {
      // Plaquetas transparentes para la nariz.
      for (final side in const [-1.0, 1.0]) {
        final pad = Rect.fromCircle(center: Offset(center.dx + side * inner * 0.85, top + lensH * 0.72), radius: d * 0.025);
        canvas.drawOval(pad, Paint()..color = Colors.white.withValues(alpha: 0.12));
        canvas.drawOval(pad, stroke(d * 0.006, color: finish.base.withValues(alpha: 0.5)));
      }
    } else {
      // Remaches metálicos en las bisagras, típicos del acetato.
      for (final side in const [-1.0, 1.0]) {
        final stud = Offset(center.dx + side * (offsetX + lensW * 0.4), top + lensH * 0.16);
        canvas.drawCircle(
          stud,
          rim * 0.32,
          Paint()..shader = ui.Gradient.radial(stud, rim * 0.4, const [Colors.white, Color(0xFF9AA1AB)]),
        );
      }
    }
    canvas.restore();
  }

  /// Lente con dos reflejos diagonales: casi transparente, o en degradado marrón si es de sol ([sun]).
  void _drawLens(Canvas canvas, Path lens, double w, {required bool sun}) {
    final box = lens.getBounds();
    final tint = sun ? const [Color(0xB04A2C17), Color(0x407A4E2E)] : const [Color(0x2690A4C0), Color(0x0890A4C0)];
    canvas.drawPath(lens, Paint()..shader = _linear(tint, box.topCenter, box.bottomCenter));
    canvas.save();
    canvas.clipPath(lens);
    canvas.drawLine(
      Offset(box.left + w * 0.15, box.bottom),
      Offset(box.left + w * 0.55, box.top),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = w * 0.1,
    );
    canvas.drawLine(
      Offset(box.left + w * 0.35, box.bottom),
      Offset(box.left + w * 0.72, box.top),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = w * 0.04,
    );
    canvas.restore();
  }

  /// Contorno de un lente centrado en ([cx], [cy]); [side] es -1 para el izquierdo y 1 para el derecho.
  Path _lensPath(double cx, double cy, double w, double h, double side) {
    final left = cx - w / 2;
    final topY = cy - h / 2;
    switch (style) {
      case TryOnStyle.oval:
        return Path()..addOval(Rect.fromLTWH(left, topY, w, h));
      case TryOnStyle.aviator:
        // Gota: arriba casi recta y la parte baja más ancha hacia afuera.
        double x(double t) => cx + side * t * w;
        return Path()
          ..moveTo(x(-0.46), topY + h * 0.06)
          ..quadraticBezierTo(x(0.05), topY - h * 0.04, x(0.5), topY + h * 0.02)
          ..cubicTo(x(0.56), topY + h * 0.45, x(0.42), topY + h * 0.95, x(0.08), topY + h)
          ..cubicTo(x(-0.25), topY + h * 1.02, x(-0.5), topY + h * 0.6, x(-0.46), topY + h * 0.06)
          ..close();
      case TryOnStyle.rectangular || TryOnStyle.browline || TryOnStyle.square:
        final radius = h * (style == TryOnStyle.square ? 0.2 : 0.18);
        return Path()..addRRect(RRect.fromLTRBR(left, topY, left + w, topY + h, Radius.circular(radius)));
    }
  }

  /// Degradado del armazón: brillo de metal, moteado de carey o relieve de acetato.
  static Shader _finishShader(FrameFinish finish, Rect bounds, double d) {
    final base = finish.base;
    Color mix(Color to, double t) => Color.lerp(base, to, t)!;
    if (finish.tortoise) {
      return _linear(
        const [Color(0xFF2E170A), Color(0xFF8A4B1C), Color(0xFF3B1F0E), Color(0xFFB8702F), Color(0xFF4A2610)],
        bounds.topLeft,
        bounds.topLeft + Offset(d * 0.22, d * 0.12),
        TileMode.mirror,
      );
    }
    final colors = finish.metal
        ? [mix(Colors.white, 0.6), base, mix(Colors.black, 0.35), mix(Colors.white, 0.3), mix(Colors.black, 0.2)]
        : [mix(Colors.white, 0.22), base, mix(Colors.black, 0.3)];
    return _linear(colors, bounds.topCenter, bounds.bottomCenter);
  }

  /// Degradado de [from] a [to], con los colores repartidos por igual.
  static Shader _linear(List<Color> colors, Offset from, Offset to, [TileMode tileMode = TileMode.clamp]) =>
      ui.Gradient.linear(from, to, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)], tileMode);

  @override
  bool shouldRepaint(GlassesPainter oldDelegate) =>
      oldDelegate.eyes != eyes || oldDelegate.style != style || oldDelegate.finish != finish;
}
