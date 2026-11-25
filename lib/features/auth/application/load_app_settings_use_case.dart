import 'package:logix_optiflow/features/auth/domain/app_settings.dart';
import 'package:logix_optiflow/features/auth/domain/session_repository.dart';

class LoadAppSettingsUseCase {
  const LoadAppSettingsUseCase({required this.repository});

  final SessionRepository repository;

  Future<AppSettings> execute() => repository.readSettings();
}
