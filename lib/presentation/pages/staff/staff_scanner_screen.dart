import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

const _scanBg = Color(0xFF1F3A6D);
const _scanPanel = Color(0xFF1E4383);

/// Los SKU del catálogo solo tienen letras, números y guiones; otros códigos (QR con enlaces, etc.) se ignoran.
final _skuPattern = RegExp(r'^[A-Z0-9-]{1,100}$');

/// Al volver del detalle la montura suele seguir frente a la cámara: ese mismo código se ignora unos segundos.
const _sameCodePause = Duration(seconds: 3);

/// Escáner de códigos de barras y QR, igual a Kotlin: lee con la cámara trasera (ML Kit, sin internet)
/// y abre el producto; también se puede escribir el SKU.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _code = TextEditingController();
  final _camera = MobileScannerController(
    formats: const [BarcodeFormat.code128, BarcodeFormat.code39, BarcodeFormat.ean13, BarcodeFormat.qrCode],
  );
  String? _lastCode;
  DateTime _resumedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _opening = false;

  @override
  void dispose() {
    _code.dispose();
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.map((b) => b.rawValue?.trim()).firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;
    final sku = raw.toUpperCase();
    final repeated = sku == _lastCode && DateTime.now().difference(_resumedAt) < _sameCodePause;
    if (!_skuPattern.hasMatch(sku) || repeated || _opening) return;
    _lastCode = sku;
    _openProduct(sku);
  }

  /// La cámara se apaga mientras se ve el producto y vuelve a encenderse al regresar.
  Future<void> _openProduct(String sku) async {
    _opening = true;
    await _camera.stop();
    if (!mounted) return;
    await context.push('/s/product/${Uri.encodeComponent(sku)}');
    _opening = false;
    _resumedAt = DateTime.now();
    if (mounted) await _camera.start();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _scanBg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/s/inventory'),
                  child: const Icon(LucideIcons.chevronLeft, size: 24, color: AppColors.white),
                ),
                Expanded(
                  child: Column(children: [
                    Text('Escanear producto', style: AppFonts.inter(fontSize: 14, color: AppColors.white)),
                    Text('Apunta al código de la montura', style: AppFonts.inter(fontSize: 9, color: AppColors.white.withValues(alpha: 0.8))),
                  ]),
                ),
                const Icon(LucideIcons.circleQuestionMark, size: 22, color: AppColors.white),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: _scanPanel,
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned.fill(
                        child: MobileScanner(
                          controller: _camera,
                          onDetect: _onDetect,
                          placeholderBuilder: (_) => const ColoredBox(color: _scanPanel),
                          errorBuilder: (context, error) => _CameraError(error, onRetry: _camera.start),
                        ),
                      ),
                      const IgnorePointer(child: CustomPaint(size: Size(250, 180), painter: _FramePainter())),
                    ]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(children: [
                StaffInput(
                  controller: _code,
                  placeholder: 'SKU, ej. RB-5154-BLK',
                  icon: LucideIcons.pencil,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                    LengthLimitingTextInputFormatter(100),
                    TextInputFormatter.withFunction((_, value) => value.copyWith(text: value.text.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 12),
                StaffButton(
                  label: 'Ver producto',
                  height: 52,
                  onPressed: _code.text.trim().isEmpty ? null : () => _openProduct(_code.text.trim()),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError(this.error, {required this.onRetry});
  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            denied
                ? 'Toca aquí para permitir la cámara (o actívala en Ajustes).\nTambién puedes escribir el SKU abajo.'
                : 'No se pudo abrir la cámara. Toca para reintentar o escribe el SKU abajo.',
            textAlign: TextAlign.center,
            style: AppFonts.inter(fontSize: 12, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

/// Esquinas blancas y la línea de lectura del recuadro.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const len = 34.0;
    final corner = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    for (final (x, y, dx, dy) in [(0.0, 0.0, 1.0, 1.0), (w, 0.0, -1.0, 1.0), (0.0, h, 1.0, -1.0), (w, h, -1.0, -1.0)]) {
      canvas.drawLine(Offset(x, y), Offset(x + len * dx, y), corner);
      canvas.drawLine(Offset(x, y), Offset(x, y + len * dy), corner);
    }
    final line = Paint()
      ..strokeWidth = 3
      ..shader = const LinearGradient(colors: [Color(0x66FFFFFF), Colors.white, Color(0x66FFFFFF)]).createShader(Rect.fromLTWH(0, h / 2, w, 3));
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
