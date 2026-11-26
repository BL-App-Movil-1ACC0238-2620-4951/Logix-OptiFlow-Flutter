import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/push/push_messaging.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/notification/application/register_device_use_case.dart';
import 'package:logix_optiflow/features/notification/presentation/notifications_view_model.dart';

/// Conecta los push con la sesión: registra el celular del paciente, lo da de baja al cerrar sesión
/// y abre Notificaciones cuando se toca un aviso.
class PushNotificationsViewModel {
  PushNotificationsViewModel({
    required this.session,
    required this.push,
    required this.registerDeviceUseCase,
    required this.notifications,
  });

  final SessionViewModel session;
  final PushMessaging push;
  final RegisterDeviceUseCase registerDeviceUseCase;
  final NotificationsViewModel notifications;

  bool _started = false;

  /// [openNotifications] lleva a la pantalla de notificaciones del paciente.
  Future<void> start(VoidCallback openNotifications) async {
    if (_started) return;
    _started = true;
    session.addSessionReadyListener(_register);
    session.addLogoutListener(() => unawaited(push.deleteToken()));
    push.onTokenRefresh.listen((_) => _register());
    push.onMessage.listen((_) => _refresh());
    void open() {
      // Solo el paciente recibe push; sin sesión de paciente se queda donde está.
      if (_isPatient) openNotifications();
    }
    push.onOpened.listen((_) => open());
    await session.bootstrap();
    if (await push.initialMessage() != null) open();
  }

  bool get _isPatient => session.session?.isPatient == true && session.session?.isAuthenticated == true;

  Future<void> _register() async {
    final current = session.session;
    if (current == null || !_isPatient) return;
    try {
      await registerDeviceUseCase.execute(current.patientId);
    } catch (_) {
      // Sin internet o sin Google Play no hay push; la app sigue igual.
    }
  }

  void _refresh() {
    if (_isPatient) unawaited(notifications.refresh());
  }
}
