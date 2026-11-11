import '../entities/models.dart';
import '../repositories/session_repository.dart';

class LoadSession {
  const LoadSession(this._sessions);

  final SessionRepository _sessions;

  Future<PatientSession?> call() => _sessions.read();
}

class SaveSession {
  const SaveSession(this._sessions);

  final SessionRepository _sessions;

  Future<void> call(PatientSession session) => _sessions.save(session);
}

class ClearSession {
  const ClearSession(this._sessions);

  final SessionRepository _sessions;

  Future<void> call() => _sessions.clear();
}

class LoadReadNotifications {
  const LoadReadNotifications(this._sessions);

  final SessionRepository _sessions;

  Future<Set<String>> call() => _sessions.readNotificationIds();
}

class SaveReadNotifications {
  const SaveReadNotifications(this._sessions);

  final SessionRepository _sessions;

  Future<void> call(Set<String> ids) => _sessions.saveNotificationIds(ids);
}

class LoadAppSettings {
  const LoadAppSettings(this._sessions);

  final SessionRepository _sessions;

  Future<AppSettings> call() => _sessions.readSettings();
}

class SaveAppSettings {
  const SaveAppSettings(this._sessions);

  final SessionRepository _sessions;

  Future<void> call(AppSettings settings) => _sessions.saveSettings(settings);
}
