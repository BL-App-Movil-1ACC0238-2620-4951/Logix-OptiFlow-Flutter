// El backend manda los push con el token de registro (FCM v1), como en Kotlin; por eso se usan
// getToken, deleteToken y onTokenRefresh aunque la versión 17 prefiera el ID de instalación.
// ignore_for_file: deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging del celular. Si Firebase no está configurado (iOS sin su archivo,
/// pruebas o sin Google Play) todo queda sin efecto y la app sigue igual, solo sin push.
class PushMessaging {
  bool _ready = false;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (_) {}
  }

  Future<String?> token() async => _ready ? FirebaseMessaging.instance.getToken() : null;

  /// Al cerrar sesión el token deja de servir y el backend lo descarta en el siguiente envío.
  Future<void> deleteToken() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  /// Desde Android 13 hay que pedir permiso para mostrar los push.
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}
  }

  Stream<String> get onTokenRefresh => _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  /// Push que llega con la app abierta (Firebase no muestra el aviso).
  Stream<RemoteMessage> get onMessage => _ready ? FirebaseMessaging.onMessage : const Stream.empty();

  /// El paciente tocó un aviso con la app en segundo plano.
  Stream<RemoteMessage> get onOpened => _ready ? FirebaseMessaging.onMessageOpenedApp : const Stream.empty();

  /// Aviso que abrió la app cuando estaba cerrada.
  Future<RemoteMessage?> initialMessage() async => _ready ? FirebaseMessaging.instance.getInitialMessage() : null;
}
