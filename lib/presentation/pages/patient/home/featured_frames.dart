import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/optiflow_controller.dart';
import '../catalog_screen.dart';

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
      if (mounted) context.read<OptiFlowController>().refreshCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    if (app.catalogLoading && app.frames.isEmpty) return const LinearProgressIndicator();
    if (app.catalogError != null && app.frames.isEmpty) {
      return TextButton(onPressed: app.refreshCatalog, child: const Text('Volver a cargar monturas'));
    }
    final featured = app.frames.take(2).toList();
    if (featured.isEmpty) return const Text('Todavía no hay monturas en el catálogo.');
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final entry in featured.indexed) ...[
        if (entry.$1 > 0) const SizedBox(width: 12),
        Expanded(child: CatalogFrameCard(frame: entry.$2)),
      ],
      if (featured.length == 1) const Expanded(child: SizedBox()),
    ]);
  }
}
