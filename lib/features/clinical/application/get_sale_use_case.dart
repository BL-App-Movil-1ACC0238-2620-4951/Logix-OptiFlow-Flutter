import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';

class GetSaleUseCase {
  const GetSaleUseCase({required this.repository});

  final CommerceRepository repository;

  Future<Sale> execute(String saleId) => repository.sale(saleId);
}
