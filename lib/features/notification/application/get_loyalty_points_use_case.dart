import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';

class GetLoyaltyPointsUseCase {
  const GetLoyaltyPointsUseCase({required this.repository});

  final NotificationRepository repository;

  Future<int> execute(String patientId) => repository.loyaltyBalance(patientId);
}
