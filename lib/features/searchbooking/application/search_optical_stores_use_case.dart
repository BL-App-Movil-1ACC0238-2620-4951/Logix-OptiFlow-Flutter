import 'package:logix_optiflow/features/searchbooking/domain/store_repository.dart';

class SearchOpticalStoresUseCase {
  const SearchOpticalStoresUseCase({required this.repository});

  final StoreRepository repository;

  Future<StoreSearchResult> execute({String? name, String? address, double? minRating}) => repository.search(name: name, address: address, minRating: minRating);
}
