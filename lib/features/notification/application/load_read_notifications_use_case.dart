import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';

class LoadReadNotificationsUseCase {
  const LoadReadNotificationsUseCase({required this.repository});

  final NotificationRepository repository;

  Future<Set<String>> execute() => repository.readNotificationIds();
}
