import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/auth/application/clear_session_use_case.dart';
import 'package:logix_optiflow/features/auth/application/load_app_settings_use_case.dart';
import 'package:logix_optiflow/features/auth/application/load_session_use_case.dart';
import 'package:logix_optiflow/features/auth/application/login_use_case.dart';
import 'package:logix_optiflow/features/auth/application/register_patient_use_case.dart';
import 'package:logix_optiflow/features/auth/application/save_app_settings_use_case.dart';
import 'package:logix_optiflow/features/auth/application/save_session_use_case.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/presentation/session_ui_state.dart';
import 'package:logix_optiflow/presentation/navigation/route_access.dart';

/// Sesión, login, registro y ajustes. Los demás ViewModels la escuchan para limpiarse al salir.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel({
    required this.api,
    required this.loadSessionUseCase,
    required this.saveSessionUseCase,
    required this.clearSessionUseCase,
    required this.loginUseCase,
    required this.registerPatientUseCase,
    required this.loadAppSettingsUseCase,
    required this.saveAppSettingsUseCase,
  }) {
    api.onUnauthorized = () { unawaited(logout()); };
  }

  final ApiClient api;
  final LoadSessionUseCase loadSessionUseCase;
  final SaveSessionUseCase saveSessionUseCase;
  final ClearSessionUseCase clearSessionUseCase;
  final LoginUseCase loginUseCase;
  final RegisterPatientUseCase registerPatientUseCase;
  final LoadAppSettingsUseCase loadAppSettingsUseCase;
  final SaveAppSettingsUseCase saveAppSettingsUseCase;

  static const minPassword = 8;

  SessionUiState _state = const SessionUiState();
  SessionUiState get state => _state;
  Future<void>? _bootstrapFuture;
  final _readyListeners = <VoidCallback>[];
  final _logoutListeners = <VoidCallback>[];

  /// Se llama al terminar el arranque (con o sin sesión) y después de cada login o registro.
  void addSessionReadyListener(VoidCallback listener) => _readyListeners.add(listener);

  /// Se llama al cerrar sesión, antes de avisar a la vista, para que cada ViewModel se limpie.
  void addLogoutListener(VoidCallback listener) => _logoutListeners.add(listener);

  PatientSession? get session => _state.session;
  @visibleForTesting
  set session(PatientSession? value) => _state = _state.copyWith(session: () => value);
  String get homeRoute => homePath(session);
  bool canOpen(String path) => canAccessPath(session, path);

  String get displayName => session?.name.trim().isNotEmpty == true ? session!.name.trim() : (session?.isPatient == false ? 'Personal' : 'Paciente');
  String get firstName => displayName.split(' ').first;
  String get email => session?.email.trim().isNotEmpty == true ? session!.email.trim() : '';
  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  void _emit(SessionUiState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> bootstrap() => _bootstrapFuture ??= _bootstrap();

  Future<void> _bootstrap() async {
    var restored = await loadSessionUseCase.execute();
    if (restored != null && !restored.isAuthenticated) {
      restored = null;
      await clearSessionUseCase.execute();
    }
    api.token = restored?.token;
    final settings = await loadAppSettingsUseCase.execute();
    _emit(_state.copyWith(session: () => restored, settings: settings, bootstrapped: true));
    for (final listener in List.of(_readyListeners)) { listener(); }
  }

  Future<void> setControlReminders(bool value) async {
    final settings = _state.settings.copyWith(controlReminders: value);
    await saveAppSettingsUseCase.execute(settings);
    _emit(_state.copyWith(settings: settings));
  }

  Future<void> _saveSession(PatientSession value) async {
    await saveSessionUseCase.execute(value);
    api.token = value.token;
    _emit(_state.copyWith(session: () => value));
  }

  Future<void> logout() async {
    api.token = null;
    _state = _state.copyWith(session: () => null);
    for (final listener in List.of(_logoutListeners)) { listener(); }
    notifyListeners();
    await clearSessionUseCase.execute();
    // Lo guardado para ver sin conexión es de esta cuenta.
    await api.offline?.clear();
  }

  String? validateAuth({
    required bool register,
    required bool clinical,
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool terms,
  }) {
    if (register && clinical) return 'Las cuentas del personal las crea el administrador de la óptica.';
    if (register && name.trim().isEmpty) return 'Ingresa tu nombre completo.';
    if (!email.contains('@')) return 'Ingresa un correo válido.';
    if (register && !clinical && phone.trim().isEmpty) return 'Ingresa tu teléfono.';
    if (password.length < minPassword) return 'La contraseña debe tener al menos $minPassword caracteres.';
    if (register && !terms) return 'Acepta los Términos de Servicio para continuar.';
    return null;
  }

  Future<void> login({required String email, required String password}) =>
      _authenticate(() => loginUseCase.execute(email: email.trim(), password: password));

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _authenticate(() async {
        await registerPatientUseCase.execute(name: name.trim(), email: email.trim(), phone: phone.trim(), password: password);
        return loginUseCase.execute(email: email.trim(), password: password);
      });

  Future<void> _authenticate(Future<PatientSession> Function() call) async {
    if (_state.busy) return;
    _emit(_state.copyWith(busy: true, error: () => null));
    String? error;
    try {
      await _saveSession(await call());
      for (final listener in List.of(_readyListeners)) { listener(); }
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      _emit(_state.copyWith(busy: false, error: () => error));
    }
  }

  void updateProfile({required String name, required String phone}) {
    final current = session;
    if (current == null) return;
    unawaited(_saveSession(current.copyWith(name: name.trim(), phone: phone.trim())));
  }

  @override
  void dispose() {
    api.onUnauthorized = null;
    super.dispose();
  }
}
