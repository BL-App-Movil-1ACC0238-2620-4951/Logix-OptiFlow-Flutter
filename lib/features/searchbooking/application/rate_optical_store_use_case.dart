import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

class RateOpticalStoreUseCase {
  const RateOpticalStoreUseCase({required this.repository});

  final StoreRepository repository;

  Future<void> execute({required String opticalStoreId, required String patientId, required int score, String? comment}) =>
      repository.rate(opticalStoreId, patientId, score, comment);
}
