import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

class SaveFavoriteStoreUseCase {
  const SaveFavoriteStoreUseCase({required this.repository});

  final StoreRepository repository;

  Future<void> execute(String patientId, String opticalStoreId) => repository.saveFavorite(patientId, opticalStoreId);
}
