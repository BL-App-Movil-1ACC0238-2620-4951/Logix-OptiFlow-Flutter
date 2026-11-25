import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/mappers/store_labels.dart';
import 'package:logix_optiflow/presentation/pages/patient/search/store_map.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

/// Mapa a pantalla completa con todas las ópticas; al tocar un pin se puede reservar ahí.
class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({super.key});

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  final _vm = getIt<StoreSearchViewModel>();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm.refreshLocation(ask: true);
      if (_vm.state.results.isEmpty) _vm.searchStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final stores = state.visibleStores;
        final selected = stores.where((s) => s.id == _selectedId).firstOrNull;
        return PatientScaffold(
          tab: PatientTab.search,
          topBar: LightTopBar(title: 'Mapa de ópticas', onBack: () => context.canPop() ? context.pop() : context.go('/p/search')),
          body: Stack(
            children: [
              Positioned.fill(
                child: StoreMap(
                  stores: stores,
                  userLocation: state.userLocation,
                  selectedStoreId: selected?.id,
                  onStoreTap: (store) => setState(() => _selectedId = store.id),
                ),
              ),
              Positioned(
                // Abajo queda espacio para el crédito de OpenStreetMap, que debe verse siempre.
                left: 16,
                right: 16,
                bottom: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ErrorBanner(state.error),
                    if (state.error != null) const SizedBox(height: 8),
                    if (selected != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selected.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            const SizedBox(height: 4),
                            Text(selected.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (state.distanceKm(selected) != null) distanceLabel(state.distanceKm(selected)!),
                                state.firstSlots[selected.id] == null ? 'Sin turnos libres' : 'Primer turno: ${firstSlotLabel(state.firstSlots[selected.id]!)}',
                              ].join(' · '),
                              style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500),
                            ),
                            const SizedBox(height: 12),
                            SolidButton(
                              label: 'Reservar cita',
                              leadingIcon: LucideIcons.calendarPlus,
                              height: 44,
                              textStyle: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                              onPressed: () => context.push('/p/book?storeId=${Uri.encodeComponent(selected.id)}'),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1))],
                        ),
                        child: Text('Toca un pin para ver la óptica', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
