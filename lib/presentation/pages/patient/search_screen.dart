import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_ui_state.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/mappers/store_labels.dart';
import 'package:logix_optiflow/presentation/pages/patient/search/store_map.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _vm = getIt<StoreSearchViewModel>();
  late final TextEditingController _query = TextEditingController(text: _vm.state.query);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm.refreshLocation();
      _vm.searchStores();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _vm.setSearchQuery(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _vm.searchStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final stores = state.visibleStores;
        return PatientScaffold(
          tab: PatientTab.search,
          topBar: LightTopBar(
            title: 'Buscar',
            onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
            trailing: BellButton(onTap: () => context.push('/p/notifications')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              SearchField(
                controller: _query,
                placeholder: 'Buscar armazón, dirección, estilo...',
                onChanged: _onQueryChanged,
                onSubmitted: (_) => _vm.searchStores(),
              ),
              const SizedBox(height: 20),
              _CatalogBanner(onTap: () => context.push('/p/catalog')),
              const SizedBox(height: 22),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in StoreFilter.values) ...[
                      if (filter.index > 0) const SizedBox(width: 10),
                      SegmentChip(
                        text: filter.label,
                        selected: state.filter == filter,
                        onTap: () => _vm.setFilter(filter),
                        selectedBg: AppColors.deepNavy,
                        selectedText: AppColors.white,
                        unselectedText: AppColors.deepNavy,
                        border: AppColors.skyTint,
                        height: 34,
                        style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _MapPreview(stores: stores, state: state, onOpen: () => context.push('/p/search/map')),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.userLocation != null ? 'Resultados cercanos' : 'Resultados',
                      style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/p/search/map'),
                    child: Text('Ver mapa', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (state.loading && stores.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.electric)),
                ),
              ErrorBanner(state.error),
              if (state.message != null) Text(state.message!, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
              for (final store in stores) ...[
                const SizedBox(height: 14),
                _StoreCard(
                  store: store,
                  distanceKm: state.distanceKm(store),
                  firstSlot: state.firstSlots[store.id],
                  favorite: state.favoriteIds.contains(store.id),
                  onFavorite: () => _vm.saveFavorite(store.id),
                  onTap: () => context.push('/p/book?storeId=${Uri.encodeComponent(store.id)}'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Campo de búsqueda redondo del paciente.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.placeholder, required this.onChanged, this.onSubmitted});
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF8B9AC0)));
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.electric,
        style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.deepNavy),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.mintWhite,
          hintText: placeholder,
          hintStyle: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate400),
          prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.patientHeader),
          contentPadding: EdgeInsets.zero,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

class _CatalogBanner extends StatelessWidget {
  const _CatalogBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 102,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.infoBanner,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.skyTint),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
              child: Text('?', style: AppFonts.plusJakartaSans(fontSize: 24, color: AppColors.deepNavy)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿YA SABES QUÉ TE GUSTA?', style: AppFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.electric)),
                  Text('Busca por montura', style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  Text('Elige un modelo y descubre dónde está disponible.', style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500, height: 1.25)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.slate500),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.stores, required this.state, required this.onOpen});
  final List<OpticalStore> stores;
  final StoreSearchUiState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final label = state.userLocation != null ? 'cerca de ti' : 'en el mapa';
    return Container(
      height: 144,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.skyTint)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: StoreMap(stores: stores, userLocation: state.userLocation, interactive: false, onMapTap: onOpen)),
          Positioned(
            left: 14,
            top: 14,
            child: GestureDetector(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1))],
                ),
                child: Text('${stores.length} ópticas $label', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.distanceKm,
    required this.firstSlot,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final OpticalStore store;
  final double? distanceKm;
  final DateTime? firstSlot;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = store.rating == null ? '—' : store.rating!.toStringAsFixed(1).replaceAll('.', ',');
    final details = [rating, if (distanceKm != null) distanceLabel(distanceKm!)].join(' · ');
    return AppCard(
      onTap: onTap,
      borderColor: AppColors.skyTint,
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.eye, background: AppColors.lavender, color: AppColors.navyBlue, size: 64, iconSize: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  firstSlot == null ? 'Sin turnos libres' : firstSlotLabel(firstSlot!),
                  background: AppColors.skyTint,
                  color: AppColors.deepNavy,
                  icon: LucideIcons.clock,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.navyBlue),
                    const SizedBox(width: 5),
                    Text(details, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Examen visual · Lentes · Monturas', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate400)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onFavorite,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(LucideIcons.heart, size: 20, color: favorite ? AppColors.electric : AppColors.slate400),
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.slate500),
        ],
      ),
    );
  }
}
