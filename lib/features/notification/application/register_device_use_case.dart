import 'package:logix_optiflow/core/push/push_messaging.dart';
import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';

/// Registra el token de push de este celular para el paciente; sin token no hace nada.
class RegisterDeviceUseCase {
  const RegisterDeviceUseCase({required this.repository, required this.push});

  final NotificationRepository repository;
  final PushMessaging push;

  Future<void> execute(String patientId) async {
    final token = await push.token();
    if (token == null || token.isEmpty) return;
    await repository.registerDevice(patientId, token);
  }
}
