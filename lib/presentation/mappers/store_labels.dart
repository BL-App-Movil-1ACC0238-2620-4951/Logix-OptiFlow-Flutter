import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/time/store_time.dart';

/// "Hoy · 10:30", "Mañana · 09:00" o "vie 14 · 16:00" para el primer turno libre de una óptica.
String firstSlotLabel(DateTime start) {
  final local = StoreTime.clock(start);
  final today = StoreTime.today();
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
