import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';

class SaveReadNotificationsUseCase {
  const SaveReadNotificationsUseCase({required this.repository});

  final NotificationRepository repository;

  Future<void> execute(Set<String> ids) => repository.saveNotificationIds(ids);
}
