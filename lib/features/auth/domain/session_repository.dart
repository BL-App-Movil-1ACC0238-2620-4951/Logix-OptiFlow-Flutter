import 'package:logix_optiflow/features/auth/domain/app_settings.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';

abstract class SessionRepository {
  Future<PatientSession?> read();

  Future<void> save(PatientSession session);

  Future<void> clear();

  Future<AppSettings> readSettings();

  Future<void> saveSettings(AppSettings settings);
}
