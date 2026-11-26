import 'package:flutter/material.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/features/inventory/presentation/catalog_view_model.dart';
import 'package:logix_optiflow/presentation/pages/patient/catalog_screen.dart';

class FeaturedFrames extends StatefulWidget {
  const FeaturedFrames({super.key});
  @override
  State<FeaturedFrames> createState() => _FeaturedFramesState();
}

class _FeaturedFramesState extends State<FeaturedFrames> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getIt<CatalogViewModel>().refreshCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = getIt<CatalogViewModel>();
    return ListenableBuilder(
      listenable: catalogVm,
      builder: (context, _) {
        if (catalogVm.state.catalogLoading && catalogVm.state.frames.isEmpty) return const LinearProgressIndicator();
        if (catalogVm.state.catalogError != null && catalogVm.state.frames.isEmpty) {
          return TextButton(onPressed: catalogVm.refreshCatalog, child: const Text('Volver a cargar monturas'));
        }
        final featured = catalogVm.state.frames.take(2).toList();
        if (featured.isEmpty) return const Text('Todavía no hay monturas en el catálogo.');
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final entry in featured.indexed) ...[
            if (entry.$1 > 0) const SizedBox(width: 12),
            Expanded(child: CatalogFrameCard(frame: entry.$2)),
          ],
          if (featured.length == 1) const Expanded(child: SizedBox()),
        ]);
        },
    );
  }
}
