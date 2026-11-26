import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';

class GetQuotationUseCase {
  const GetQuotationUseCase({required this.repository});

  final CommerceRepository repository;

  Future<Quotation> execute(String quotationId) => repository.quotation(quotationId);
}
