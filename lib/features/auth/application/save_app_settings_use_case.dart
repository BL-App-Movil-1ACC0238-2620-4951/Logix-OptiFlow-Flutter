import 'package:logix_optiflow/features/auth/domain/app_settings.dart';
import 'package:logix_optiflow/features/auth/domain/session_repository.dart';

class SaveAppSettingsUseCase {
  const SaveAppSettingsUseCase({required this.repository});

  final SessionRepository repository;

  Future<void> execute(AppSettings settings) => repository.saveSettings(settings);
}
