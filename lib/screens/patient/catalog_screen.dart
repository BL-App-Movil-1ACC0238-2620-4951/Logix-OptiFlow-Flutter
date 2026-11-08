import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/demo_data.dart';
import '../../theme/app_colors.dart';
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
    final frames = DemoData.frames.where((f) => filter == 'Todos' || f.category == filter).toList();
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
    final frame = DemoData.frame(id);
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

class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final frame = DemoData.frame(id);
    return PatientScaffold(
      tab: PatientTab.search,
      background: const Color(0xFF101428),
      topBar: DarkTopBar(title: 'Prueba virtual', onBack: () => context.pop()),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Text('Alinea tu rostro con la guía', style: GoogleFonts.inter(color: AppColors.white)),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 220, height: 280, decoration: BoxDecoration(border: Border.all(color: AppColors.skyTint, width: 2), borderRadius: BorderRadius.circular(140))),
              Image.asset(frame.image, width: 220, fit: BoxFit.contain),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(frame.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                const SizedBox(height: 8),
                Text('La cámara AR del prototipo se simula en esta versión Flutter.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate300)),
                const SizedBox(height: 16),
                SolidButton(label: 'Quiero este modelo', onPressed: () => context.push('/p/book')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
