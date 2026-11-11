import '../../domain/entities/models.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_data_source.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._local);

  final SessionLocalDataSource _local;

  @override
  Future<PatientSession?> read() => _local.read();

  @override
  Future<void> save(PatientSession session) => _local.save(session);

  @override
  Future<void> clear() => _local.clear();

  @override
  Future<Set<String>> readNotificationIds() => _local.readNotificationIds();

  @override
  Future<void> saveNotificationIds(Set<String> ids) => _local.saveNotificationIds(ids);
}
