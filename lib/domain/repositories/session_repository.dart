import '../entities/models.dart';

abstract class SessionRepository {
  Future<PatientSession?> read();

  Future<void> save(PatientSession session);

  Future<void> clear();

  Future<Set<String>> readNotificationIds();

  Future<void> saveNotificationIds(Set<String> ids);
}
