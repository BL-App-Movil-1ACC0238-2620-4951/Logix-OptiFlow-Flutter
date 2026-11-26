import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';

/// Unidades de una montura en una óptica.
class FrameStock {
  const FrameStock({required this.store, required this.quantity});

  final OpticalStore store;
  final int quantity;
}
