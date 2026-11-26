import 'package:logix_optiflow/features/inventory/domain/favorite_frame_repository.dart';

class ToggleFavoriteFrameUseCase {
  const ToggleFavoriteFrameUseCase({required this.repository});

  final FavoriteFrameRepository repository;

  Future<Set<String>> execute(String patientId, String sku) => repository.toggle(patientId, sku);
}
