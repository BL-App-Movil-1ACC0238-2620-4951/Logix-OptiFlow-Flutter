import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/presentation/pages/patient/search_screen.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/frame_photos.dart';

const _frameBorder = Color(0xFF9AA8C7);
const _ink = Color(0xFF111827);

/// "S/ 299.90".
String framePriceLabel(FrameItem frame) => 'S/ ${frame.price.toStringAsFixed(2)}';

/// Forma en mayúsculas o "MONTURA" si no tiene.
String frameShapeLabel(FrameItem frame) => frame.shape?.toUpperCase() ?? 'MONTURA';

class _FramePhoto extends StatelessWidget {
  const _FramePhoto({required this.frame});
  final FrameItem frame;

  @override
  Widget build(BuildContext context) => Image.asset(
        framePhotoFor(frame.sku),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.skyTint),
      );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _vm = getIt<CatalogViewModel>();
  final _query = TextEditingController();
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm.refreshCatalog();
      _vm.loadFavorites();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final filters = ['Todos', 'Favoritos', ...state.shapes];
        final q = _query.text.trim().toLowerCase();
        final frames = state.frames
            .where((f) => switch (_filter) {
                  0 => true,
                  1 => state.favorites.contains(f.sku),
                  _ => f.shape == (_filter < filters.length ? filters[_filter] : null),
                })
            .where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
            .toList();
        return PatientScaffold(
          tab: PatientTab.search,
          topBar: LightTopBar(
            title: 'Explorar Monturas',
            onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
            trailing: BellButton(onTap: () => context.push('/p/notifications')),
          ),
          body: RefreshIndicator(
            onRefresh: _vm.refreshCatalog,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              children: [
                SearchField(controller: _query, placeholder: 'Buscar armazón, estilo...', onChanged: (_) => setState(() {})),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        SegmentChip(
                          text: filters[i],
                          selected: _filter == i,
                          onTap: () => setState(() => _filter = i),
                          selectedBg: AppColors.patientHeader,
                          selectedText: AppColors.white,
                          unselectedText: AppColors.deepNavy,
                          border: _frameBorder,
                          height: 34,
                          style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoBanner,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.skyTint),
                  ),
                  child: Row(
                    children: [
                      const IconTile(icon: LucideIcons.star, background: AppColors.white, color: AppColors.electric, size: 42, iconSize: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Encuentra tu estilo', style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            Text(
                              'Selecciona una montura y te mostraremos qué ópticas cercanas la tienen.',
                              style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500, height: 15 / 11),
                            ),
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
                    child: Text(
                      state.catalogLoading
                          ? 'Cargando monturas...'
                          : state.catalogError ??
                              (_filter == 1
                                  ? 'Aún no tienes monturas favoritas. Toca el corazón en una montura para guardarla.'
                                  : 'No hay monturas en esta categoría por ahora.'),
                      style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500),
                    ),
                  ),
                for (var i = 0; i < frames.length; i += 3) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var j = i; j < i + 3; j++) ...[
                        if (j > i) const SizedBox(width: 16),
                        Expanded(
                          child: j < frames.length
                              ? _CatalogCard(frame: frames[j], onTap: () => context.push('/p/frame/${Uri.encodeComponent(frames[j].sku)}'))
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.frame, required this.onTap});
  final FrameItem frame;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 16,
      borderColor: _frameBorder,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 116, child: _FramePhoto(frame: frame))),
          const SizedBox(height: 14),
          Text(frameShapeLabel(frame), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.electric)),
          const SizedBox(height: 4),
          Text(frame.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 4),
          Text(framePriceLabel(frame), maxLines: 1, style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal700)),
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
  final _vm = getIt<CatalogViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_vm.frameById(widget.id) == null) _vm.loadFrame(widget.id);
      _vm.loadFavorites();
      _vm.loadStock(widget.id);
    });
  }

  void _back() => context.canPop() ? context.pop() : context.go('/p/catalog');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final frame = _vm.frameById(widget.id);
        final favorite = state.favorites.contains(widget.id);
        final stock = state.stock;
        final units = stock?.fold<int>(0, (sum, s) => sum + s.quantity) ?? 0;
        return PatientScaffold(
          tab: PatientTab.search,
          topBar: LightTopBar(
            title: 'Detalles de montura',
            onBack: _back,
            trailing: GestureDetector(
              onTap: () => _vm.toggleFavorite(widget.id),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.bellChip, shape: BoxShape.circle),
                child: Icon(favorite ? Icons.favorite : LucideIcons.heart, size: 20, color: AppColors.patientHeader),
              ),
            ),
          ),
          body: frame == null
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.frameLoading.contains(widget.id)) const LinearProgressIndicator(),
                    ErrorBanner(state.frameErrors[widget.id]),
                    if (state.frameErrors[widget.id] != null)
                      TextButton(onPressed: () => _vm.loadFrame(widget.id), child: const Text('Reintentar')),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Container(
                      height: 220,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: _frameBorder)),
                      child: Stack(
                        children: [
                          Positioned.fill(child: _FramePhoto(frame: frame)),
                          if (units > 0)
                            const Padding(
                              padding: EdgeInsets.all(14),
                              child: Pill(
                                'DISPONIBLE HOY',
                                background: AppColors.mint100,
                                color: AppColors.emerald700,
                                icon: LucideIcons.circleCheck,
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                iconSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      radius: 16,
                      borderColor: _frameBorder,
                      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${frameShapeLabel(frame)} · UNISEX', style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.electric)),
                          const SizedBox(height: 6),
                          Text(frame.name, style: AppFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
                          const SizedBox(height: 10),
                          Text(
                            [frame.material, frame.color].whereType<String>().join(' · '),
                            style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500),
                          ),
                          const SizedBox(height: 18),
                          Text(framePriceLabel(frame), style: AppFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.electric)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const IconTile(icon: LucideIcons.packageCheck, background: AppColors.mint100, color: AppColors.emerald700, size: 30, iconSize: 16, radius: 15),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stock == null
                                          ? 'Consultando stock...'
                                          : units > 0
                                              ? 'En stock · $units unidades'
                                              : 'Sin stock por ahora',
                                      style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald700),
                                    ),
                                    Text('Disponible para prueba y reserva inmediata', style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.skyTint),
                          const SizedBox(height: 12),
                          Text('Características principales', style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (i, feature) in [frame.material, frame.shape].whereType<String>().indexed)
                                Pill(
                                  feature,
                                  background: AppColors.skyTint,
                                  color: AppColors.navyBlue,
                                  icon: i == 0 ? LucideIcons.gem : LucideIcons.leaf,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  iconSize: 14,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => context.go('/p/search'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.infoBanner, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const IconTile(icon: LucideIcons.mapPin, background: AppColors.white, color: AppColors.navyBlue),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      switch ((stock ?? const []).length) {
                                        0 => 'Consulta la disponibilidad en tu óptica',
                                        1 => 'Disponible en 1 óptica',
                                        final n => 'Disponible en $n ópticas',
                                      },
                                      style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                                    ),
                                    Text(
                                      stock != null && stock.isNotEmpty ? 'Por ejemplo, en ${stock.first.store.name}.' : 'Toca para ver las ópticas.',
                                      style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 52),
                    // "Probar virtualmente" se agrega con el probador de cámara (rama 22).
                    SolidButton(
                      label: 'Ver ópticas con disponibilidad',
                      onPressed: () => context.push('/p/book'),
                      leadingIcon: LucideIcons.mapPin,
                      textStyle: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// El probador con cámara llega en su propia rama; mientras tanto se abre el detalle.
class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => FrameDetailScreen(id: id);
}
