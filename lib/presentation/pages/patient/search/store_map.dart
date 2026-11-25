import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/domain/geo_point.dart';
import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';

/// Centro de Lima, para cuando no hay ubicación del usuario ni ópticas con coordenadas.
const _lima = LatLng(-12.1, -77.03);

/// "Hoy · 10:30", "Mañana · 09:00" o "vie 14 · 16:00" para el primer turno libre de una óptica.
String firstSlotLabel(DateTime start) {
  final local = start.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final dayLabel = day == today
      ? 'Hoy'
      : day == today.add(const Duration(days: 1))
          ? 'Mañana'
          : DateFormat('EEE d', 'es').format(local).replaceAll('.', '');
  return '$dayLabel · ${DateFormat('HH:mm').format(local)}';
}

/// "0,8 km" con coma decimal; desde 10 km sin decimales.
String distanceLabel(double km) => '${km < 10 ? km.toStringAsFixed(1).replaceAll('.', ',') : km.toStringAsFixed(0)} km';

/// Mapa de OpenStreetMap con un pin por óptica en sus coordenadas del backend y un punto azul en
/// la ubicación del usuario. Con [interactive] en false es la vista previa de la búsqueda: no se
/// mueve y cualquier toque llama a [onMapTap].
class StoreMap extends StatelessWidget {
  const StoreMap({
    super.key,
    required this.stores,
    required this.userLocation,
    this.interactive = true,
    this.selectedStoreId,
    this.onStoreTap,
    this.onMapTap,
  });

  final List<OpticalStore> stores;
  final GeoPoint? userLocation;
  final bool interactive;
  final String? selectedStoreId;
  final ValueChanged<OpticalStore>? onStoreTap;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    final located = stores.where((s) => s.hasLocation).toList();
    final user = userLocation;
    final center = user != null
        ? LatLng(user.latitude, user.longitude)
        : located.isNotEmpty
            ? LatLng(
                located.map((s) => s.latitude!).reduce((a, b) => a + b) / located.length,
                located.map((s) => s.longitude!).reduce((a, b) => a + b) / located.length,
              )
            : _lima;
    final map = FlutterMap(
      // Al cambiar el centro (llega la ubicación o cambian las ópticas) el mapa se vuelve a centrar.
      key: ValueKey('${center.latitude},${center.longitude}'),
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
        interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OpenStreetMap pide identificar la app.
          userAgentPackageName: 'com.logix.logix_optiflow',
        ),
        MarkerLayer(
          markers: [
            for (final store in located)
              Marker(
                point: LatLng(store.latitude!, store.longitude!),
                width: 34,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onStoreTap == null ? null : () => onStoreTap!(store),
                  child: Opacity(
                    opacity: selectedStoreId == null || selectedStoreId == store.id ? 1 : 0.6,
                    child: const CustomPaint(size: Size(34, 44), painter: _StorePinPainter()),
                  ),
                ),
              ),
            if (user != null)
              Marker(
                point: LatLng(user.latitude, user.longitude),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                ),
              ),
          ],
        ),
        // Crédito obligatorio de OpenStreetMap.
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            color: AppColors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text('© OpenStreetMap contributors', style: AppFonts.inter(fontSize: 9, color: AppColors.slate600)),
          ),
        ),
      ],
    );
    if (interactive) return map;
    return GestureDetector(onTap: onMapTap, behavior: HitTestBehavior.opaque, child: IgnorePointer(child: map));
  }
}

/// Pin de óptica: gota azul con centro blanco; la punta queda abajo al centro.
class _StorePinPainter extends CustomPainter {
  const _StorePinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(17, 1)
      ..cubicTo(8.2, 1, 1, 8.1, 1, 16.9)
      ..cubicTo(1, 28.8, 17, 43, 17, 43)
      ..cubicTo(17, 43, 33, 28.8, 33, 16.9)
      ..cubicTo(33, 8.1, 25.8, 1, 17, 1)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.electric);
    canvas.drawPath(path, Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    canvas.drawCircle(const Offset(17, 17), 6, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
