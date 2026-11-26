import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/presentation/pages/patient/catalog_screen.dart';
import 'package:logix_optiflow/presentation/pages/patient/try_on/face_camera.dart';
import 'package:logix_optiflow/presentation/pages/patient/try_on/try_on_glasses.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/frame_photos.dart';

/// Probador virtual (US21): cámara frontal con la montura dibujada sobre los ojos.
class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key, required this.id});
  final String id;

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final _vm = getIt<CatalogViewModel>();
  final _eyes = ValueNotifier<EyePositions?>(null);
  bool _hasCamera = true;
  bool _noCamera = false;
  int _cameraKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _vm.frameById(widget.id) == null) _vm.loadFrame(widget.id);
    });
  }

  @override
  void dispose() {
    _eyes.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/p/catalog');

  /// Vuelve a abrir la cámara, que pide el permiso otra vez si hace falta.
  void _retryCamera() => setState(() {
        _hasCamera = true;
        _cameraKey++;
      });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final frame = _vm.frameById(widget.id);
        final style = frame == null ? null : tryOnStyleOf(frame);
        if (frame == null || style == null) {
          // Sin modelo de prueba virtual no hay probador (US21, escenario 2).
          final loading = _vm.state.frameLoading.contains(widget.id);
          if (!loading && (frame != null || _vm.state.frameErrors[widget.id] != null)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _back();
            });
          }
          return const Scaffold(backgroundColor: _night, body: Center(child: CircularProgressIndicator(color: Colors.white)));
        }
        final finish = tryOnFinishOf(frame);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: _night,
            body: Column(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(colors: [Color(0xFF2B4F96), _night, Color(0xFF0D1C44)]),
                    ),
                    child: ValueListenableBuilder<EyePositions?>(
                      valueListenable: _eyes,
                      builder: (context, eyes, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_hasCamera) ...[
                            FaceCamera(
                              key: ValueKey(_cameraKey),
                              // Se suaviza el movimiento para que la montura no tiemble.
                              onEyes: (found) => _eyes.value = found == null ? null : (_eyes.value?.towards(found) ?? found),
                              onUnavailable: (noCamera) => setState(() {
                                _hasCamera = false;
                                _noCamera = noCamera;
                              }),
                            ),
                            CustomPaint(painter: GlassesPainter(style, finish, eyes)),
                            if (eyes == null) const CustomPaint(painter: _CameraGuide()),
                          ] else
                            Center(
                              child: GestureDetector(
                                onTap: _noCamera ? null : _retryCamera,
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    _noCamera
                                        ? 'Este dispositivo no tiene cámara, así que el probador virtual no está disponible.'
                                        : 'Toca aquí para permitir la cámara (o actívala en Ajustes).',
                                    textAlign: TextAlign.center,
                                    style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.white),
                                  ),
                                ),
                              ),
                            ),
                          SafeArea(
                            bottom: false,
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      _CameraButton(icon: LucideIcons.chevronLeft, onTap: _back),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Prueba virtual', style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                                            Text(
                                              '${frame.name} · Cámara AR',
                                              style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.white.withValues(alpha: 0.7)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                    ],
                                  ),
                                ),
                                if (_hasCamera)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, top: 70),
                                    child: _GlassPill(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: eyes != null ? const Color(0xFF60A5FA) : AppColors.slate400,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          eyes != null ? 'Rostro detectado' : 'Buscando tu rostro…',
                                          style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_hasCamera)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 36,
                              child: Center(
                                child: _GlassPill(
                                  horizontal: 16,
                                  vertical: 8,
                                  children: [
                                    const Icon(LucideIcons.eye, size: 14, color: AppColors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mira de frente y mantén el rostro dentro de la guía',
                                      style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                framePhotoFor(frame.sku),
                                width: 62,
                                height: 62,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(width: 62, height: 62, child: ColoredBox(color: AppColors.skyTint)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PROBANDO AHORA', style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric)),
                                  Text(
                                    frame.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                                  ),
                                  Text(
                                    [frame.color, framePriceLabel(frame)].whereType<String>().join(' · '),
                                    style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/p/frame/${Uri.encodeComponent(frame.sku)}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(color: AppColors.skyTint, borderRadius: BorderRadius.circular(10)),
                                child: Text('Ver stock', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PatientBottomBar(selected: PatientTab.search),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _night = Color(0xFF14295A);

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(icon, size: 20, color: AppColors.white),
        ),
      );
}

/// Píldora oscura semitransparente sobre la cámara.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.children, this.horizontal = 12, this.vertical = 6});
  final List<Widget> children;
  final double horizontal;
  final double vertical;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        decoration: BoxDecoration(
          color: const Color(0x40000000),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
}

/// Guía de rostro (rejilla y óvalo punteado) mientras no se detecta una cara.
class _CameraGuide extends CustomPainter {
  const _CameraGuide();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    canvas.drawLine(Offset(0, size.height * 0.52), Offset(size.width, size.height * 0.52), grid);
    final oval = Path()
      ..addOval(Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.55), width: size.width * 0.44, height: size.height * 0.6));
    final dash = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final ui.PathMetric metric in oval.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 24) {
        canvas.drawPath(metric.extractPath(start, start + 14), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_CameraGuide oldDelegate) => false;
}
