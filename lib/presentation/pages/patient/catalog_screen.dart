import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/frame.dart';
import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int filter = 0;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final frames = context.watch<OptiFlowController>().frames.where((frame) {
      final matches = switch (filter) {
        1 => frame.category == 'SOLAR',
        2 => frame.category == 'OFTÁLMICO',
        3 => false,
        _ => true,
      };
      final text = query.trim().toLowerCase();
      return matches && (text.isEmpty || frame.name.toLowerCase().contains(text));
    }).toList();
    return PatientScaffold(
      tab: PatientTab.search,
      topBar: LightTopBar(
        title: 'Explorar Monturas',
        onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
        trailing: IconButton(onPressed: () => context.push('/p/notifications'), icon: const Icon(Icons.notifications_none_rounded, color: AppColors.patientHeader)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Buscar armazón, estilo...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9AA8C7))),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _Filter(['Todos', 'Solar', 'Oftálmico', 'Contacto'][i], filter == i, () => setState(() => filter = i)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.infoBanner, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.skyTint)),
            child: Row(
              children: [
                const IconTile(icon: Icons.star_outline, background: AppColors.white, color: AppColors.electric, size: 42, iconSize: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Encuentra tu estilo', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      Text('Selecciona una montura y te mostraremos qué ópticas cercanas la tienen.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (frames.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No hay monturas en esta categoría por ahora.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
            ),
          for (var i = 0; i < frames.length; i += 2) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CatalogCard(frames[i])),
                const SizedBox(width: 16),
                Expanded(child: i + 1 < frames.length ? _CatalogCard(frames[i + 1]) : const SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.patientHeader : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9AA8C7)),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? AppColors.white : AppColors.deepNavy)),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard(this.frame);
  final FrameItem frame;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      onTap: () => context.push('/p/frame/${frame.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(frame.image, height: 116, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 14),
          Text(frame.category, style: GoogleFonts.inter(fontSize: 11, color: AppColors.electric)),
          const SizedBox(height: 4),
          Text(frame.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('\$${frame.price}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal700)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class FrameDetailScreen extends StatefulWidget {
  const FrameDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<FrameDetailScreen> createState() => _FrameDetailScreenState();
}

class _FrameDetailScreenState extends State<FrameDetailScreen> {
  bool favorite = false;

  @override
  Widget build(BuildContext context) {
    final frame = context.watch<OptiFlowController>().frameById(widget.id);
    return PatientScaffold(
      tab: PatientTab.search,
      topBar: LightTopBar(
        title: 'Detalles de montura',
        onBack: () => context.pop(),
        trailing: IconButton(
          onPressed: () => setState(() => favorite = !favorite),
          icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: AppColors.patientHeader),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(frame.image, fit: BoxFit.cover),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.emerald600),
                          const SizedBox(width: 4),
                          Text('DISPONIBLE HOY', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald600)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.patientHeader.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)),
                      child: Text('1 de 3', style: GoogleFonts.inter(fontSize: 12, color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${frame.category} · UNISEX', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric)),
                const SizedBox(height: 6),
                Text(frame.name, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 10),
                Text(frame.description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 18),
                Text(frame.fromPrice, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.electric)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const IconTile(icon: Icons.inventory_2_outlined, background: AppColors.emerald50, color: AppColors.emerald600, size: 30, iconSize: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('En stock · ${frame.stock} unidades', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald600)),
                          Text('Disponible para prueba y reserva inmediata', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.skyTint),
                const SizedBox(height: 12),
                Text('Características principales', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < frame.features.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: AppColors.skyTint, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(i == 0 ? Icons.diamond_outlined : Icons.eco_outlined, size: 14, color: AppColors.navyBlue),
                            const SizedBox(width: 4),
                            Text(frame.features[i], style: GoogleFonts.inter(fontSize: 12, color: AppColors.navyBlue)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => context.go('/p/search'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.infoBanner, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const IconTile(icon: Icons.place_outlined, background: AppColors.white, color: AppColors.navyBlue),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disponible en 3 ópticas cercanas', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                        Text('La más cercana está a 0,8 km de ti.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          SolidButton(label: 'Ver ópticas con disponibilidad', icon: Icons.place_outlined, onPressed: () => context.push('/p/book')),
          const SizedBox(height: 10),
          SolidButton(
            label: 'Probar en AR',
            icon: Icons.photo_camera_outlined,
            background: AppColors.white,
            foreground: AppColors.electric,
            border: AppColors.skyTint,
            onPressed: () => context.push('/p/tryon/${frame.id}'),
          ),
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
