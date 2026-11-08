import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';
import 'search/catalog_prompt.dart';
import 'search/store_result_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _chip = 0;

  static const _chips = ['Todas', 'Abiertas', 'Mejor valoradas', '4.5+', '4.0+'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OptiFlowController>().searchStores());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    var stores = app.stores;
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
              context.read<OptiFlowController>().setSearchQuery(value);
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => context.read<OptiFlowController>().searchStores());
            },
            decoration: InputDecoration(
              hintText: 'Buscar armazón, dirección, estilo...',
              prefixIcon: const Icon(Icons.search, color: AppColors.slate500),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyTint)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyTint)),
            ),
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
                    final app = context.read<OptiFlowController>();
                    if (index == 3) {
                      app.setMinRating(4.5);
                    } else if (index == 4) {
                      app.setMinRating(4);
                    } else if (app.minRating != null) {
                      app.setMinRating(null);
                    }
                  },
                  selectedColor: AppColors.deepNavy,
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: selected ? AppColors.white : AppColors.deepNavy),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.skyTint),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _MapPreview(count: stores.length),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Text('Resultados cercanos', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy))),
              Text('Mapa', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
            ],
          ),
          const SizedBox(height: 12),
          if (app.searchLoading && stores.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.electric))),
          if (app.searchError != null)
            Text(app.searchError!, style: GoogleFonts.inter(color: AppColors.errorRed)),
          if (!app.searchLoading && stores.isEmpty)
            Text(app.searchMessage ?? 'No encontramos ópticas con ese filtro.', style: GoogleFonts.inter(color: AppColors.slate500)),
          for (var i = 0; i < stores.length; i++) ...[
            StoreResultCard(store: stores[i], index: i),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFD9E5FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _MapHatchPainter())),
              Positioned(left: width * 0.18, top: 28, child: const _MapPin()),
              Positioned(left: width * 0.62, top: 36, child: const _MapPin()),
              Positioned(left: width * 0.40, top: 78, child: const _MapPin()),
              Positioned(
                left: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    '$count ópticas cerca de ti',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.patientHeader,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: const Icon(Icons.location_on, size: 15, color: AppColors.white),
    );
  }
}

class _MapHatchPainter extends CustomPainter {
  const _MapHatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7EEFD)
      ..strokeWidth = 14;
    const step = 34.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
