import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';
import 'package:logix_optiflow/features/notification/infrastructure/notification_local_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required this.local});

  final NotificationLocalDataSource local;

  @override
  Future<Set<String>> readNotificationIds() => local.readNotificationIds();

  @override
  Future<void> saveNotificationIds(Set<String> ids) => local.saveNotificationIds(ids);
}
