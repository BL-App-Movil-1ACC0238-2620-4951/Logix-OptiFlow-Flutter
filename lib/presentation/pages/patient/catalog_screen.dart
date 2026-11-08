import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final frames = context.watch<OptiFlowController>().frames.where((f) => filter == 'Todos' || f.category == filter).toList();
    return PatientScaffold(
      tab: PatientTab.search,
      topBar: LightTopBar(title: 'Explorar monturas', onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: [
                  for (final label in const ['Todos', 'OFTÁLMICO', 'SOLAR'])
                    ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      selected: filter == label,
                      onSelected: (_) => setState(() => filter = label),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68),
        itemCount: frames.length,
        itemBuilder: (context, index) {
          final frame = frames[index];
          return AppCard(
            padding: const EdgeInsets.all(8),
            onTap: () => context.push('/p/frame/${frame.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(frame.image, width: double.infinity, fit: BoxFit.cover))),
                const SizedBox(height: 8),
                Text(frame.category, style: GoogleFonts.inter(fontSize: 11, color: AppColors.warmGray)),
                Text(frame.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                Text('\$${frame.price}.00', style: GoogleFonts.inter(color: AppColors.teal700)),
              ],
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}

class FrameDetailScreen extends StatelessWidget {
  const FrameDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final frame = context.watch<OptiFlowController>().frameById(id);
    return PatientScaffold(
      tab: PatientTab.search,
      topBar: LightTopBar(title: frame.name, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset(frame.image, height: 240, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          Text(frame.category, style: GoogleFonts.inter(color: AppColors.warmGray, letterSpacing: 1)),
          Text(frame.name, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          Text(frame.description, style: GoogleFonts.inter(color: AppColors.slate500)),
          const SizedBox(height: 8),
          Text('\$${frame.price}.00', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.teal700)),
          Text('${frame.stock} en stock · calibre ${frame.size}', style: GoogleFonts.inter(color: AppColors.slate500)),
          const SizedBox(height: 16),
          Text('Características', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [for (final feature in frame.features) Chip(label: Text(feature))]),
          const SizedBox(height: 12),
          Text('Colores', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [for (final color in frame.colors) Chip(label: Text(color))]),
          const SizedBox(height: 20),
          SolidButton(label: 'Probar en AR', icon: Icons.photo_camera_outlined, onPressed: () => context.push('/p/tryon/${frame.id}')),
          const SizedBox(height: 10),
          SolidButton(label: 'Buscar dónde está', background: AppColors.white, foreground: AppColors.electric, border: AppColors.skyTint, onPressed: () => context.go('/p/search')),
        ],
      ),
    );
  }
}

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key, required this.id});
  final String id;

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  int _color = 0;

  @override
  Widget build(BuildContext context) {
    final frame = context.watch<OptiFlowController>().frameById(widget.id);
    final colors = frame.colors.isEmpty ? const ['Azul marino'] : frame.colors;
    final selected = colors[_color.clamp(0, colors.length - 1)];
    return PatientScaffold(
      tab: PatientTab.search,
      background: const Color(0xFF14295A),
      topBar: const SizedBox.shrink(),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF2B4F96), Color(0xFF14295A), Color(0xFF0D1C44)], radius: 1.1)))),
                const Positioned.fill(child: CustomPaint(painter: _CameraGuidePainter())),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        _CameraButton(icon: Icons.chevron_left, onTap: () => context.pop()),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Prueba virtual', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                              Text('${frame.name} · Cámara AR', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xB3FFFFFF))),
                            ],
                          ),
                        ),
                        const _CameraButton(icon: Icons.help_outline),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 86,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x40000000),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF60A5FA), shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text('Rostro detectado', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 28,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.white),
                          const SizedBox(width: 8),
                          Flexible(child: Text('Mira de frente y mantén el rostro dentro de la guía', style: GoogleFonts.inter(fontSize: 11, color: AppColors.white))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(frame.image, width: 62, height: 62, fit: BoxFit.cover)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PROBANDO AHORA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric)),
                          Text(frame.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                          Text('$selected · Talla ${frame.size}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/p/frame/${frame.id}'),
                      style: TextButton.styleFrom(backgroundColor: AppColors.skyTint, foregroundColor: AppColors.electric),
                      child: const Text('Ver stock'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Elige un color', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < colors.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _color = i),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: i == _color ? AppColors.electric : const Color(0xFFE2E8F0), width: i == _color ? 2 : 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(color: _swatch(colors[i], i), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCBD5E1))),
                              ),
                              const SizedBox(width: 8),
                              Text(colors[i], style: GoogleFonts.inter(fontSize: 12, fontWeight: i == _color ? FontWeight.w700 : FontWeight.w500, color: i == _color ? AppColors.deepNavy : AppColors.slate500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x33000000),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x33FFFFFF))),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }
}

class _CameraGuidePainter extends CustomPainter {
  const _CameraGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    canvas.drawLine(Offset(0, size.height * 0.52), Offset(size.width, size.height * 0.52), grid);

    final ovalW = size.width * 0.44;
    final ovalH = size.height * 0.6;
    final center = Offset(size.width / 2, size.height * 0.55);
    final oval = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(Rect.fromCenter(center: center, width: ovalW, height: ovalH), oval);

    final frame = Paint()
      ..color = const Color(0xFF14254F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final lensW = ovalW * 0.62;
    final lensH = lensW * 0.55;
    final gap = ovalW * 0.18;
    final y = center.dy - lensH * 0.9;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - gap / 2 - lensW, y, lensW, lensH), const Radius.circular(14)), frame);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx + gap / 2, y, lensW, lensH), const Radius.circular(14)), frame);
    canvas.drawLine(Offset(center.dx - gap / 2, y + lensH * 0.3), Offset(center.dx + gap / 2, y + lensH * 0.3), frame);
    canvas.drawLine(Offset(center.dx - gap / 2 - lensW, y + lensH * 0.2), Offset(center.dx - gap / 2 - lensW - 20, y + lensH * 0.15), frame);
    canvas.drawLine(Offset(center.dx + gap / 2 + lensW, y + lensH * 0.2), Offset(center.dx + gap / 2 + lensW + 20, y + lensH * 0.15), frame);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _swatch(String name, int index) {
  final key = name.toLowerCase();
  if (key.contains('azul')) return const Color(0xFF1E3D79);
  if (key.contains('cristal')) return const Color(0xFFF1F5F9);
  if (key.contains('carey') || key.contains('ámbar') || key.contains('ambar')) return const Color(0xFF8B5A2B);
  if (key.contains('negro')) return const Color(0xFF111827);
  if (key.contains('dorado')) return const Color(0xFFD4A017);
  if (key.contains('plata')) return const Color(0xFFCBD5E1);
  const fallback = [Color(0xFF1E3D79), Color(0xFFF1F5F9), Color(0xFF0013C1)];
  return fallback[index % fallback.length];
}
