import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/frame.dart';
import '../../state/optiflow_controller.dart';
import '../../widgets/chrome.dart';
import '../../widgets/frame_image.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';

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
    final q = query.trim().toLowerCase();
    final frames = app.frames.where((frame) => '${frame.name} ${frame.sku} ${frame.description}'.toLowerCase().contains(q)).toList();
    return PatientScaffold(
      tab: PatientTab.search,
      topBar: LightTopBar(title: 'Explorar monturas', onBack: () => context.canPop() ? context.pop() : context.go('/p/home')),
      body: RefreshIndicator(
        onRefresh: app.refreshCatalog,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20),
          children: [
            TextField(onChanged: (value) => setState(() => query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Nombre, SKU, material o forma')),
            const SizedBox(height: 16),
            if (app.catalogLoading) const LinearProgressIndicator(),
            if (app.catalogError != null) ...[
              Text(app.catalogError!, style: const TextStyle(color: AppColors.errorRed)),
              TextButton(onPressed: app.refreshCatalog, child: const Text('Reintentar')),
            ],
            if (!app.catalogLoading && app.catalogError == null && frames.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No hay monturas con esos criterios.')),
            for (var i = 0; i < frames.length; i += 2) ...[
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: CatalogFrameCard(frame: frames[i])),
                const SizedBox(width: 12),
                Expanded(child: i + 1 < frames.length ? CatalogFrameCard(frame: frames[i + 1]) : const SizedBox()),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class CatalogFrameCard extends StatelessWidget {
  const CatalogFrameCard({super.key, required this.frame});
  final FrameItem frame;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    onTap: () => context.push('/p/frame/${Uri.encodeComponent(frame.id)}'),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FrameImage(path: frame.image, height: 120),
      const SizedBox(height: 12),
      Text(frame.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
      Text(frame.sku, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      Text(frame.fromPrice, style: const TextStyle(color: AppColors.electric, fontWeight: FontWeight.bold)),
    ]),
  );
}

class FrameDetailScreen extends StatefulWidget {
  const FrameDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<FrameDetailScreen> createState() => _FrameDetailScreenState();
}

class _FrameDetailScreenState extends State<FrameDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OptiFlowController>().loadFrame(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final frame = app.frameById(widget.id);
    return PatientScaffold(
      tab: PatientTab.search,
      topBar: LightTopBar(title: 'Detalles de montura', onBack: () => context.canPop() ? context.pop() : context.go('/p/catalog')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (app.frameLoading.contains(widget.id)) const LinearProgressIndicator(),
        if (app.frameErrors[widget.id] != null) ...[
          Text(app.frameErrors[widget.id]!, style: const TextStyle(color: AppColors.errorRed)),
          TextButton(onPressed: () => app.loadFrame(widget.id), child: const Text('Reintentar')),
        ],
        if (frame != null) ...[
          FrameImage(path: frame.image, height: 230),
          const SizedBox(height: 20),
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(frame.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('SKU: ${frame.sku}'),
            const SizedBox(height: 12),
            Text(frame.fromPrice, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(frame.description),
            const SizedBox(height: 12),
            const Text('Consulta la disponibilidad con la óptica antes de tu visita.'),
          ])),
          const SizedBox(height: 20),
          SolidButton(label: 'Buscar una óptica', icon: Icons.place_outlined, onPressed: () => context.go('/p/search')),
        ],
      ]),
    );
  }
}

// Old preview links continue to open the real SKU details. No simulated camera.
class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => FrameDetailScreen(id: id);
}
