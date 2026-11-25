import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase({required this.repository});

  final NotificationRepository repository;

  Future<void> execute(String id) => repository.markRead(id);
}
