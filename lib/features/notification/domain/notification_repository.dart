/// Notificaciones que el paciente ya leyó en este dispositivo.
abstract class NotificationRepository {
  Future<Set<String>> readNotificationIds();

  Future<void> saveNotificationIds(Set<String> ids);
}
