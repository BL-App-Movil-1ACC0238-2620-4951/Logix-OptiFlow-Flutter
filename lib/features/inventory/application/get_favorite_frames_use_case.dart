import 'package:logix_optiflow/features/inventory/domain/favorite_frame_repository.dart';

class GetFavoriteFramesUseCase {
  const GetFavoriteFramesUseCase({required this.repository});

  final FavoriteFrameRepository repository;

  Future<Set<String>> execute(String patientId) => repository.favorites(patientId);
}
