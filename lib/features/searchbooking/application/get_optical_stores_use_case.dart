import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

class GetOpticalStoresUseCase {
  const GetOpticalStoresUseCase({required this.repository});

  final StoreRepository repository;

  Future<List<OpticalStore>> execute({String? name, String? address}) => repository.list(name: name, address: address);
}
