import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/pages/patient/search/catalog_prompt.dart';
import 'package:logix_optiflow/presentation/pages/patient/search/store_result_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  late final TextEditingController _address;
  Timer? _debounce;
  int _chip = 0;

  static const _chips = ['Todas', 'Activas', 'Mejor valoradas', '4.5+', '4.0+'];

  @override
  void initState() {
    super.initState();
    final storesVm = getIt<StoreSearchViewModel>();
    _query = TextEditingController(text: storesVm.state.query);
    _address = TextEditingController(text: storesVm.state.address);
    _chip = storesVm.state.minRating == 4.5 ? 3 : storesVm.state.minRating == 4 ? 4 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) storesVm.searchStores(); });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storesVm = getIt<StoreSearchViewModel>();
    return ListenableBuilder(
      listenable: storesVm,
      builder: (context, _) {
        var stores = storesVm.state.results;
        if (_chip == 1) {
          stores = stores.where((s) => const {'ACTIVE', 'OPEN', 'ABIERTO'}.contains(s.status.toUpperCase())).toList();
        } else if (_chip == 2) {
          stores = [...stores]..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        }

        return PatientScaffold(
          tab: PatientTab.search,
          topBar: LightTopBar(
            title: 'Buscar',
            onBack: () => context.canPop() ? context.pop() : context.go('/p/home'),
            trailing: IconButton(onPressed: () => context.push('/p/notifications'), icon: const Icon(Icons.notifications_none_rounded, color: AppColors.patientHeader)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              TextField(
                controller: _query,
                onChanged: (value) {
                  getIt<StoreSearchViewModel>().setSearchQuery(value);
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), () => getIt<StoreSearchViewModel>().searchStores());
                },
                decoration: InputDecoration(
                  hintText: 'Nombre de la óptica',
                  prefixIcon: const Icon(Icons.search, color: AppColors.slate500),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyTint)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyTint)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                onChanged: (value) {
                  getIt<StoreSearchViewModel>().setSearchAddress(value);
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), () {
                    if (mounted) getIt<StoreSearchViewModel>().searchStores();
                  });
                },
                decoration: const InputDecoration(labelText: 'Dirección o distrito', prefixIcon: Icon(Icons.place_outlined)),
              ),
              const SizedBox(height: 16),
              CatalogPrompt(onTap: () => context.push('/p/catalog')),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final selected = _chip == index;
                    return ChoiceChip(
                      label: Text(_chips[index]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _chip = index);
                        if (index == 3) {
                          storesVm.setMinRating(4.5);
                        } else if (index == 4) {
                          storesVm.setMinRating(4);
                        } else if (storesVm.state.minRating != null) {
                          storesVm.setMinRating(null);
                        }
                      },
                      selectedColor: AppColors.deepNavy,
                      labelStyle: AppFonts.inter(fontSize: 13, color: selected ? AppColors.white : AppColors.deepNavy),
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.skyTint),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text('Ópticas encontradas', style: AppFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy))),
                  Text('${stores.length}', style: AppFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
                ],
              ),
              const SizedBox(height: 12),
              if (storesVm.state.loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.electric))),
              if (storesVm.state.error != null) ...[
                Text(storesVm.state.error!, style: AppFonts.inter(color: AppColors.errorRed)),
                TextButton(onPressed: storesVm.searchStores, child: const Text('Reintentar')),
              ],
              if (!storesVm.state.loading && storesVm.state.error == null && stores.isEmpty)
                Text(storesVm.state.message ?? 'No encontramos ópticas con ese filtro.', style: AppFonts.inter(color: AppColors.slate500)),
              if (!storesVm.state.loading && storesVm.state.error == null) for (var i = 0; i < stores.length; i++) ...[
                StoreResultCard(store: stores[i]),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
        },
    );
  }
}
