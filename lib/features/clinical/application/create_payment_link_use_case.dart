import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';

class CreatePaymentLinkUseCase {
  const CreatePaymentLinkUseCase({required this.repository});

  final CommerceRepository repository;

  Future<String> execute(String saleId) => repository.paymentLink(saleId);
}
