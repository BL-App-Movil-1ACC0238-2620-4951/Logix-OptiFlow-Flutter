import 'package:logix_optiflow/features/auth/domain/app_settings.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/session_repository.dart';
import 'package:logix_optiflow/features/auth/infrastructure/session_local_data_source.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({required this.local});

  final SessionLocalDataSource local;

  @override
  Future<PatientSession?> read() => local.read();

  @override
  Future<void> save(PatientSession session) => local.save(session);

  @override
  Future<void> clear() => local.clear();

  @override
  Future<AppSettings> readSettings() => local.readSettings();

  @override
  Future<void> saveSettings(AppSettings settings) => local.saveSettings(settings);
}
